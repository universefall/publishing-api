require 'rails_helper'

RSpec.describe Command::CreateDraft do
  subject { described_class.new }

  let(:event_payload) {
    {
      "content_id" => "ab12b610-166d-4495-972b-90cfe360aa21",
      "title" => "Get Britain Building: Carlisle Park",
      "description" => "Nearly 400 homes...",
      "locale" => "en",
      "public_updated_at" => "2012-12-17T15:45:44.000+00:00",
      "update_type" => "major",
      "details" => {
        "body" => "# Heading\n\nParagraph body.",
        "first_public_at" => "2012-12-17T15:45:44+00:00"
      }
    }
  }

  let(:event) {
    instance_double("Event", name: "create_draft", payload: event_payload)
  }

  it "creates a draft content item using the payload" do
    subject.call(event)

    expect(DraftContentItem.count).to eq(1)

    item = DraftContentItem.first
    expect(item.title).to eq(event_payload['title'])
    expect(item.content_id).to eq(event_payload['content_id'])
    expect(item.description).to eq(event_payload['description'])
    expect(item.locale).to eq(event_payload['locale'])
    expect(item.public_updated_at).to eq(event_payload['public_updated_at'])
    expect(item.details).to eq(event.payload['details'])
  end
end
