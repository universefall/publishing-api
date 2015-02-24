package main

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/gorilla/mux"

	"github.com/alphagov/publishing-api/contentstore"
	"github.com/alphagov/publishing-api/urlarbiter"
)

type ContentStoreController struct {
	arbiter           *urlarbiter.URLArbiter
	liveContentStore  *contentstore.ContentStoreClient
	draftContentStore *contentstore.ContentStoreClient
}

type ContentStoreRequest struct {
	PublishingApp string `json:"publishing_app"`
}

func NewContentStoreController(arbiterURL, liveContentStoreURL, draftContentStoreURL string) *ContentStoreController {
	return &ContentStoreController{
		arbiter:           urlarbiter.NewURLArbiter(arbiterURL),
		liveContentStore:  contentstore.NewClient(liveContentStoreURL),
		draftContentStore: contentstore.NewClient(draftContentStoreURL),
	}
}

func (controller *ContentStoreController) PutDraftContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	controller.registerWithURLArbiterAndForward(w, r, func(basePath string, requestBody []byte) {
		controller.doContentStoreRequest(controller.draftContentStore, "PUT", strings.Replace(basePath, "draft-", "", -1), requestBody, w)
	})
}

func (controller *ContentStoreController) PutContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	controller.registerWithURLArbiterAndForward(w, r, func(basePath string, requestBody []byte) {
		// TODO: PUT to both content stores concurrently
		controller.doContentStoreRequest(controller.liveContentStore, "PUT", basePath, requestBody, w)
		// for now, we ignore the response from draft content store for storing live content, hence `w` is nil
		controller.doContentStoreRequest(controller.draftContentStore, "PUT", basePath, requestBody, nil)
	})
}

func (controller *ContentStoreController) PutPublishIntentRequest(w http.ResponseWriter, r *http.Request) {
	controller.registerWithURLArbiterAndForward(w, r, func(basePath string, requestBody []byte) {
		controller.doContentStoreRequest(controller.liveContentStore, "PUT", basePath, requestBody, w)
	})
}

func (controller *ContentStoreController) GetContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	controller.doContentStoreRequest(controller.liveContentStore, "GET", r.URL.Path, nil, w)
}

func (controller *ContentStoreController) DeleteContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	controller.doContentStoreRequest(controller.liveContentStore, "DELETE", r.URL.Path, nil, w)
}

func (controller *ContentStoreController) registerWithURLArbiterAndForward(w http.ResponseWriter, r *http.Request,
	afterRegister func(basePath string, requestBody []byte)) {

	urlParameters := mux.Vars(r)
	if requestBody, contentStoreRequest := controller.readRequest(w, r); contentStoreRequest != nil {
		if !controller.registerWithURLArbiter(urlParameters["base_path"], contentStoreRequest.PublishingApp, w) {
			return
		}
		afterRegister(r.URL.Path, requestBody)
	}
}

// Register the given path and publishing app with the URL arbiter.  Returns
// true on success.  On failure, writes an error to the ResponseWriter, and
// returns false
func (controller *ContentStoreController) registerWithURLArbiter(basePath, publishingApp string, w http.ResponseWriter) bool {
	urlArbiterResponse, err := controller.arbiter.Register(basePath, publishingApp)
	if err != nil {
		switch err {
		case urlarbiter.ConflictPathAlreadyReserved:
			renderer.JSON(w, http.StatusConflict, urlArbiterResponse)
		case urlarbiter.UnprocessableEntity:
			renderer.JSON(w, 422, urlArbiterResponse) // Unprocessable Entity.
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return false
	}
	return true
}

// data will be nil for requests without bodies
func (controller *ContentStoreController) doContentStoreRequest(contentStoreClient *contentstore.ContentStoreClient,
	httpMethod string, basePath string, data []byte, w http.ResponseWriter) {

	resp, err := contentStoreClient.DoRequest(httpMethod, basePath, data)

	if w != nil {
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}
		defer resp.Body.Close()

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}
}

func (controller *ContentStoreController) readRequest(w http.ResponseWriter, r *http.Request) ([]byte, *ContentStoreRequest) {
	requestBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
		return nil, nil
	}

	var contentStoreRequest *ContentStoreRequest
	if err := json.Unmarshal(requestBody, &contentStoreRequest); err != nil {
		switch err.(type) {
		case *json.SyntaxError:
			renderer.JSON(w, http.StatusBadRequest, err)
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return nil, nil
	}

	return requestBody, contentStoreRequest
}
