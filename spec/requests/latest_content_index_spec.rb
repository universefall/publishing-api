require "rails_helper"

RSpec.describe "GET /v2/latestcontent", type: :request do

  context "input parameter validation" do

    it "defaults to the first batch when last_seen_content_id is not provided" do

      create_content_items('0001', '0002', '0003')

      expected_result = [
        hash_including(content_id: make_test_id('0001')),
      ]

      get "/v2/latestcontent", count: 1

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

    it "defaults to a reasonable batch size when count is not provided" do

      create_n_content_items(11)

      get "/v2/latestcontent", last_seen_content_id: '00000000-0000-0000-0000-000000000000'

      expect(response.status).to eq(200)
      expect(results(response).size).to eq(10)
    end

    it "422s when count is not parsed as an integer" do

      get "/v2/latestcontent", count: 'not a valid integer'

      expect(response.status).to eq(422)
    end

    it "422s when count is too large" do

      get "/v2/latestcontent", count: 1001

      expect(response.status).to eq(422)
    end

    it "422s when last_seen_content_id is not parsed as a uuid" do

      get "/v2/latestcontent", last_seen_content_id: 'not a valid uuid', count: 1

      expect(response.status).to eq(422)
    end
  end

  context "batching by content_id" do

    it "delivers all content items matching the content_ids contained in the batch" do

      create_content_items('0001', '0002', '0003', '0005', '0007', '0008')

      expected_result = [
        hash_including(content_id: make_test_id('0005')),
        hash_including(content_id: make_test_id('0007')),
      ]

      get "/v2/latestcontent", last_seen_content_id: make_test_id('0003'), count: 2

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

    it "delivers a partial batch when reaching the final content_id" do

      create_content_items('0001', '0002', '0003', '0005', '0007', '0008')

      expected_result = [
        hash_including(content_id: make_test_id('0008')),
      ]

      get "/v2/latestcontent", last_seen_content_id: make_test_id('0007'), count: 2

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

    it "delivers an empty batch when reading beyond the final content_id" do

      create_content_items('0001', '0002', '0003', '0005', '0007', '0008')

      expected_result = []

      get "/v2/latestcontent", last_seen_content_id: make_test_id('0008'), count: 2

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

  end

  context "response format" do

    it "delivers expected content fields" do

      expected_result = [
          # todo...
      ]

      get "/v2/latestcontent", count: 1

      expect(response.status).to eq(200)
    end

  end

private

  def results(response)
    JSON.parse(response.body, symbolize_names: true)[:results]
  end

  def create_n_content_items(count)
    create_content_items(*((1..count).to_a.map { |i| i.to_s.rjust(4, '0') }))
  end

  def create_content_items(*ids)
    ids.each { |id| create_content_item(id) }
  end

  def create_content_item(id)
    test_content_id = make_test_id(id)
    FactoryGirl.create(:content_item,
                       content_id: test_content_id,
                       base_path: "/#{test_content_id}",
    )
  end

  # requires a 4-digit id string
  def make_test_id(id)
    # arbitrary type-4 uuid with easier ordering for readable tests
    uuid = "7c88c837-b76c-496d-b112-9a5a50b0#{id}"
  end
end
