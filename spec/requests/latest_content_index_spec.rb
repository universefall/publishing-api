require "rails_helper"

RSpec.describe "GET /v2/latestcontent", type: :request do

  create_content_item(:item1)
  create_content_item(:item2)

  context "input parameter validation" do

    it "defaults to the first batch when last_seen_content_id is not provided" do

      expected_result = [
          # todo...
          hash_including(title: "Policy 1"),
          hash_including(title: "Policy 2"),
      ]

      get "/v2/latestcontent", count: 1

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

    it "defaults to a reasonable batch size when count is not provided" do

      expected_result = [
          # todo...
          hash_including(title: "Policy 1"),
          hash_including(title: "Policy 2"),
      ]

      get "/v2/latestcontent", last_seen_content_id: '00000000-0000-0000-0000-000000000000'

      expect(response.status).to eq(200)
      expect(results(response)).to have_size(10)
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

      expected_result = [
          # todo...
          hash_including(title: "Policy 1"),
          hash_including(title: "Policy 2"),
      ]

      get "/v2/latestcontent", last_seen_content_id: '00000000-1111-0000-0000-000000000000', count: 2

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

    it "delivers a partial batch when reaching the final content_id" do

      expected_result = [
          # todo...
          hash_including(title: "Policy 1"),
      ]

      get "/v2/latestcontent", last_seen_content_id: '00000000-1111-0000-0000-000000000000', count: 2

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

    it "delivers an empty batch when reading beyond the final content_id" do

      expected_result = []

      get "/v2/latestcontent", last_seen_content_id: '00000000-1111-0000-0000-000000000000', count: 2

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end

  end

  context "response format" do

    it "delivers expected content fields" do

      expected_result = [
          # todo...
          hash_including(title: "Policy 1"),
          hash_including(title: "Policy 2"),
      ]

      get "/v2/latestcontent", count: 1

      expect(response.status).to eq(200)
      expect(results(response)).to match_array(expected_result)
    end
  end

private

  def results(response)
    JSON.parse(response.body, symbolize_names: true)[:results]
  end

  def create_content_item(name, state = 'draft', format = 'policy')
    let!(name) {
      FactoryGirl.create(:content_item,
                         state: state,
                         format: format,
                         title: "Test Policy Title",
      )
    }
  end
end
