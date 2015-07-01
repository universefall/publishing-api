package integration

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"

	main "github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("Draft Content Item Requests", func() {
	contentItem := map[string]interface{}{
		"base_path":      "/vat-rates",
		"title":          "VAT Rates",
		"description":    "VAT rates for goods and services",
		"format":         "guide",
		"publishing_app": "mainstream_publisher",
		"locale":         "en",
		"details": map[string]interface{}{
			"app":      "or format",
			"specific": "data...",
		},
		"access_limited": map[string]interface{}{
			"users": []string{
				"f17250b0-7540-0131-f036-005056030202",
				"74c7d700-5b4a-0131-7a8e-005056030037",
			},
		},
	}

	var testPublishingAPI *httptest.Server
	var testURLArbiter, testDraftContentStore, testLiveContentStore *ghttp.Server
	var endpoint string

	var expectedResponse HTTPTestResponse

	// Mock server configurations. A default is set in the BeforeEach, but can be
	// overridden if needed in your test.
	var urlArbiterResponseCode int
	var urlArbiterResponseBody string

	BeforeEach(func() {
		// URL arbiter mock server - default response (override in your test if needed)
		urlArbiterResponseCode = http.StatusOK
		urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher"}`

		TestRequestOrderTracker = make(chan TestRequestLabel, 3)

		testURLArbiter = ghttp.NewServer()
		testDraftContentStore = ghttp.NewServer()
		testLiveContentStore = ghttp.NewServer()
		testPublishingAPI = httptest.NewServer(main.BuildHTTPMux(testURLArbiter.URL(), testLiveContentStore.URL(), testDraftContentStore.URL(), nil))
		endpoint = testPublishingAPI.URL + "/draft-content/vat-rates"

		// Set expectation and canned response for URL arbiter dummy server
		testURLArbiter.AppendHandlers(ghttp.CombineHandlers(
			trackRequest(URLArbiterRequestLabel),
			ghttp.VerifyRequest("PUT", "/paths/vat-rates"),
			ghttp.VerifyJSON(`{"publishing_app": "mainstream_publisher"}`),
			ghttp.RespondWithPtr(&urlArbiterResponseCode, &urlArbiterResponseBody, http.Header{"Content-Type": []string{"application/json"}}),
		))
	})

	AfterEach(func() {
		testURLArbiter.Close()
		testDraftContentStore.Close()
		testLiveContentStore.Close()
		testPublishingAPI.Close()
		close(TestRequestOrderTracker)
	})

	Describe("PUT /draft-content", func() {
		Context("when URL arbiter errs", func() {
			It("returns a 422 status with the original response and doesn't store content", func() {
				urlArbiterResponseCode = 422
				urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is not valid"]}}`

				actualResponse := doJSONRequest("PUT", endpoint, contentItem)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: 422, Body: urlArbiterResponseBody}
				assertSameResponse(actualResponse, &expectedResponse)
			})

			It("returns a 409 status with the original response and doesn't store content", func() {
				urlArbiterResponseCode = 409
				urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is already taken"]}}`

				actualResponse := doJSONRequest("PUT", endpoint, contentItem)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: 409, Body: urlArbiterResponseBody}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})

		It("registers a path with URL arbiter and then publishes the content only to the draft content store including access limiting information", func() {
			testDraftContentStore.AppendHandlers(ghttp.CombineHandlers(
				trackRequest(DraftContentStoreRequestLabel),
				ghttp.VerifyRequest("PUT", "/content/vat-rates"),
				ghttp.VerifyJSONRepresenting(contentItem),
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem),
			))

			actualResponse := doJSONRequest("PUT", endpoint, contentItem)

			Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
			Expect(testDraftContentStore.ReceivedRequests()).To(HaveLen(1))
			Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

			expectedBody, _ := json.Marshal(contentItem)
			expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: string(expectedBody[:])}
			assertSameResponse(actualResponse, &expectedResponse)
			assertRequestOrder(URLArbiterRequestLabel, DraftContentStoreRequestLabel)
		})

		It("returns a 400 error if given invalid JSON", func() {
			actualResponse := doRequest("PUT", endpoint, []byte("i'm not json"))

			Expect(testURLArbiter.ReceivedRequests()).To(BeZero())
			Expect(testDraftContentStore.ReceivedRequests()).To(BeZero())
			Expect(testLiveContentStore.ReceivedRequests()).To(BeZero())

			expectedResponseBody := `{"message": "Invalid JSON in request body: invalid character 'i' looking for beginning of value"}`
			expectedResponse = HTTPTestResponse{Code: http.StatusBadRequest, Body: expectedResponseBody}
			assertSameResponse(actualResponse, &expectedResponse)
		})

		Describe("with SUPPRESS_DRAFT_STORE_502_ERROR set to 1", func() {
			It("returns a 200 OK when draft content store is not running", func() {
				os.Setenv("SUPPRESS_DRAFT_STORE_502_ERROR", "1")
				defer os.Unsetenv("SUPPRESS_DRAFT_STORE_502_ERROR")

				testDraftContentStore.AppendHandlers(ghttp.RespondWith(http.StatusBadGateway, ``))

				actualResponse := doJSONRequest("PUT", endpoint, contentItem)

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: ""}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})
	})
})
