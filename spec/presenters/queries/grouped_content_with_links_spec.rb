require "rails_helper"

module Presenters
  module Queries
    RSpec.describe GroupedContentWithLinks do
      before do
        FactoryGirl.create_list(:content_item, 5)

        @content_items = ContentItem.first(5)

        @content_items.each do |content_item|
          FactoryGirl.create(
            :link_set,
            content_id: content_item.content_id,
            links: {
              "topics" => [SecureRandom.uuid]
            }
          )
        end
      end

      context "when it receives query results" do
        it "presents attributes as a hash" do
          results = ::Queries::GetGroupedContentAndLinks.call
          presenter = Presenters::Queries::GroupedContentWithLinks.new(results)
          presented = presenter.present
          expect(presented).to be_kind_of(Hash)
          
        end
      end
    end
  end
end
