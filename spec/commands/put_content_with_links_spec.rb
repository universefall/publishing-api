require 'rails_helper'

RSpec.describe Commands::PutContentWithLinks do

  describe 'call with content_item_links' do
    let(:content_id) { SecureRandom.uuid }
    let(:org_content_id) { SecureRandom.uuid }

    let(:payload) {
      build(DraftContentItem)
        .as_json
        .deep_symbolize_keys
        .merge(
          content_id: content_id,
          links:    { organisation: [ org_content_id] },
        )
    }

    it "saves a ContentItemLink" do
      expect(Link.all.count).to eq(0)

      expect { Commands::PutContentWithLinks.new(payload).call(downstream: false) }.to_not raise_error

      expect(Link.all.count).to eq(1)
    end
  end
end
