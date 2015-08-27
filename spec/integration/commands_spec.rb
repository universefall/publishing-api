require "rails_helper"

RSpec.describe "Commands controller", :type => :request do
  let(:content_id) { "b65478c3-9744-4537-a5d2-b5ee6648df3b" }

  let(:content_item) {
    {
      "content_id" => content_id,
      "title" => "Original title",
      "details" => {
        "something" => "detailed"
      }
    }
  }

  context "No authenticated user" do
    let(:headers) { { format: :json } }

    specify "POST /create-draft gets a 401 unauthorized error" do
      post "/create-draft", content_item.to_json, headers

      expect(response.status).to eq(401)
      expect(response.body).to eq({error: {code: 401, message: "unauthorized"}}.to_json)
    end
  end

  let(:user) { User.create(name: "Example user") }

  let(:headers) {
    { 'X-Govuk-Authenticated-User' => user.id, format: :json }
  }

  around do |example|
    # Freeze time
    Timecop.freeze(Time.zone.parse("2011-01-01 10:10:10 +00:00")) do
      example.call
    end
  end

  describe "POST /create-draft" do
    it "creates a draft and logs the event" do
      post "/create-draft", content_item.to_json, headers
      expect(DraftContentItem.count).to eq(1)
      expect(Event.count).to eq(1)
      expect(response.body).to eq(%Q({"event_id":#{Event.first.id}}))
    end
  end

  describe "POST /publish" do
    context "a draft exists" do
      before do
        post "/create-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", details: {}}.to_json, headers
      end

      it "converts the draft to a live document and removes the draft" do
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
        expect(DraftContentItem.count).to eq(0)
        expect(Event.count).to eq(2)
        expect(LiveContentItem.count).to eq(1)
        expect(response.body).to eq(%Q({"event_id":#{Event.last.id}}))
      end

      let(:change_note) { "Changed something" }

      context "a major change" do
        before do
          post "/publish", publish_command_payload.to_json, headers
          @item = LiveContentItem.last
        end

        context "no change note provided" do
          let(:publish_command_payload) {
            {
              content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b",
              update_type: "major",
            }
          }

          it "reports an error" do
            expect(response.status).to eq(422)
            response_json = JSON.parse(response.body)
            expect(response_json.keys).to eq(["error"])
            expect(response_json['error']['code']).to eq(422)
            expect(response_json['error']['fields'].keys).to eq(['change_note'])
            expect(response_json['error']['fields']['change_note']).to eq('required for major update')
          end
        end

        context "change note provided" do
          let(:publish_command_payload) {
            {
              content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b",
              update_type: "major",
              change_note: change_note,
            }
          }

          it "records the change note in the details['change_history'] of the document" do
            expect(@item.details['change_history']).to eq([
              {
                "public_timestamp" => Time.zone.now.iso8601,
                "note" => change_note
              }
            ])
          end
        end
      end
    end
  end

  describe "POST /redraft" do
    context "a published document exists" do
      before do
        post "/create-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", details: {}}.to_json, headers
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
      end

      it "redrafting a published document" do
        post "/redraft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
        expect(Event.count).to eq(3)
        expect(DraftContentItem.count).to eq(1)
        expect(LiveContentItem.count).to eq(1)
        expect(DraftContentItem.first.attributes).to match(
          a_hash_including(LiveContentItem.first.attributes.except("id", "version"))
        )
      end
    end

    context "a published document with a change note exists" do
      let(:change_note) { "My change note" }

      before do
        post "/create-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", details: {}}.to_json, headers
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", update_type: "major", change_note: change_note}.to_json, headers
      end

      it "creates a draft excluding change_history" do
        post "/redraft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
        expect(Event.count).to eq(3)
        expect(DraftContentItem.count).to eq(1)
        expect(LiveContentItem.count).to eq(1)
        expect(LiveContentItem.first.details['change_history']).to match([
          a_hash_including("note" => change_note)
        ])
        expect(DraftContentItem.first.details).not_to match(a_hash_including('change_history'))
      end
    end
  end

  describe "POST /modify-draft" do
    context "a draft exists" do
      before do
        post "/create-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", title: "Original title", details: {something: "detailed"}}.to_json, headers
      end

      it "updates top level attributes only, leaving details unchanged" do
        post "/modify-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", title: "New title"}.to_json, headers
        expect(Event.count).to eq(2)
        expect(DraftContentItem.count).to eq(1)
        expect(LiveContentItem.count).to eq(0)
        attributes = DraftContentItem.first.attributes
        expect(attributes['title']).to eq("New title")
        expect(attributes['details']['something']).to eq("detailed")
      end

      it "replaces the details hash entirely" do
        post "/modify-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", details: {something_else: "detailed"}}.to_json, headers
        expect(DraftContentItem.count).to eq(1)
        attributes = DraftContentItem.first.attributes
        expect(attributes['title']).to eq("Original title")
        expect(attributes['details']).not_to have_key("something")
        expect(attributes['details']['something_else']).to eq("detailed")
      end
    end
  end

  describe "GET /draft/:content_id/history" do
    context "draft exists" do
      before do
        post "/create-draft", content_item.to_json, headers
      end

      it "returns the history of the draft" do
        get "/draft/#{content_item['content_id']}/history"

        expect(response.status).to eq(200)
        parsed = JSON.parse(response.body)

        expect(parsed).to eq([
          {
            "timestamp" => Time.zone.now.iso8601,
            "user_id" => user.id,
            "action" => 'create_draft',
            "event_id" => Event.first.id,
            "version" => 1
          }
        ])
      end
    end

    context "published twice" do
      before do
        post "/create-draft", content_item.to_json, headers
        post "/publish", {content_id: content_id}.to_json, headers
        post "/redraft", {content_id: content_id}.to_json, headers
        post "/publish", {content_id: content_id}.to_json, headers
      end

      it "has the redrafting and publishing in the editorial change history" do
        get "/draft/#{content_item['content_id']}/history"

        parsed = JSON.parse(response.body)
        expect(parsed).to match([
          a_hash_including("action" => "create_draft", "version" => 1),
          a_hash_including("action" => "publish", "version" => 1),
          a_hash_including("action" => "redraft", "version" => 1),
          a_hash_including("action" => "publish", "version" => 2),
        ])
      end
    end
  end

  describe "POST /editorial-note" do
    context "draft exists" do
      before do
        post "/create-draft", content_item.to_json, headers
      end

      it "inserts the editorial note into the history of the draft" do
        Timecop.freeze(1.day.from_now)

        post "/editorial-note", {content_id: content_id, note: "This is my note"}.to_json, headers
        expect(response.status).to eq(200)

        get "/draft/#{content_item['content_id']}/history"

        parsed = JSON.parse(response.body)
        expect(parsed).to match([
          a_hash_including(
            {
              "action" => 'create_draft'
            }
          ),
          a_hash_including(
            {
              "timestamp" => Time.zone.now.iso8601,
              "action" => 'editorial_note',
              "note" => 'This is my note'
            }
          ),
        ])
      end
    end
  end

  describe "GET /draft" do
    context "no draft exists" do
      it "returns a 404" do
        get "/draft/b65478c3-9744-4537-a5d2-b5ee6648df3b"
        expect(response.status).to eq(404)
        expect(response.body).to eq({error: {code: 404, message: "not found"}}.to_json)
      end
    end

    context "draft exists" do
      let(:draft_content_item) {
        JSON.parse({content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", title: "Original title", details: {something: "detailed"}}.to_json)
      }

      before do
        post "/create-draft", draft_content_item.to_json, headers
      end

      it "returns the draft" do
        get "/draft/b65478c3-9744-4537-a5d2-b5ee6648df3b"
        expect(response.status).to eq(200)
        parsed = JSON.parse(response.body)
        draft_content_item.each do |k,v|
          expect(parsed[k]).to eq(v)
        end
      end
    end
  end

  describe "GET /live/:content_id" do
    context "no published item exists" do
      it "returns a 404" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b"
        expect(response.status).to eq(404)
        expect(response.body).to eq({error: {code: 404, message: "not found"}}.to_json)
      end
    end

    context "draft exists" do
      before do
        post "/create-draft", content_item.to_json, headers
      end

      it "returns a 404" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b"
        expect(response.status).to eq(404)
        expect(response.body).to eq({error: {code: 404, message: "not found"}}.to_json)
      end
    end

    context "published document exists" do
      before do
        post "/create-draft", content_item.to_json, headers
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
      end

      it "returns the published document" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b"
        expect(response.status).to eq(200)
        parsed = JSON.parse(response.body)
        content_item.each do |k,v|
          expect(parsed[k]).to eq(v)
        end
      end
    end
  end

  describe "GET /live/:content_id/:version_number" do
    context "a document which has been published once" do
      before do
        post "/create-draft", content_item.to_json, headers
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
      end

      it "returns the document by version number" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b/1"
        expect(response.status).to eq(200)
        parsed = JSON.parse(response.body)
        content_item.each do |k,v|
          expect(parsed[k]).to eq(v)
        end
      end
    end

    context "a document which has been published twice" do
      before do
        post "/create-draft", content_item.to_json, headers
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
        post "/redraft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
        post "/modify-draft", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b", title: "New title"}.to_json, headers
        post "/publish", {content_id: "b65478c3-9744-4537-a5d2-b5ee6648df3b"}.to_json, headers
      end

      it "returns the first published document for version 1" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b/1"
        expect(response.status).to eq(200)
        parsed = JSON.parse(response.body)
        expect(parsed['title']).to eq(content_item['title'])
      end

      it "returns the second published document for version 2" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b/2"
        expect(response.status).to eq(200)
        parsed = JSON.parse(response.body)
        expect(parsed['title']).to eq('New title')
      end

      it "returns a 404 error for version 3" do
        get "/live/b65478c3-9744-4537-a5d2-b5ee6648df3b/3"
        expect(response.status).to eq(404)
      end
    end
  end

  describe "publishing multiple major changes with change notes" do
    before do
      post "/create-draft", content_item.to_json, headers
      post "/publish", content_item.merge(update_type: "major", change_note: "First change note").to_json, headers
      post "/redraft", content_item.to_json, headers
      post "/publish", content_item.merge(update_type: "major", change_note: "Second change note").to_json, headers
    end

    it "accumulates each change note in the change history" do
      get "/live/#{content_item['content_id']}"
      parsed = JSON.parse(response.body)
      expect(parsed['details']['change_history']).to match([
        a_hash_including("note" => "First change note"),
        a_hash_including("note" => "Second change note")
      ])
    end
  end
end
