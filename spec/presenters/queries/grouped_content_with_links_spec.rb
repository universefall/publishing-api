require "rails_helper"

module Presenters
  module Queries
    RSpec.describe GroupedContentWithLinks do
      describe "#present" do
        context "when receives an empty array" do
          it "returns a hash with empty results" do
            presenter = Presenters::Queries::GroupedContentWithLinks.new([])

            expect(presenter.present).to eq(
              {
                last_seen_content_id: nil,
                results: []
              }
            )
          end
        end

        context "when receives an array of results" do
          let(:content_id) { SecureRandom.uuid }
          let(:topic_content_id) { SecureRandom.uuid }

          before do
            FactoryGirl.create(
              :content_item,
              content_id: content_id,
              base_path: "/such-base-path",
              publishing_app: "whitehall",
              locale: "en",
              format: "guide",
              user_facing_version: 1,
              state: "published"
            )

            FactoryGirl.create(
              :content_item,
              content_id: content_id,
              base_path: "/such-base-path",
              publishing_app: "whitehall",
              locale: "en",
              format: "guide",
              user_facing_version: 2,
              state: "draft",
            )

            FactoryGirl.create(
              :link_set,
              content_id: content_id,
              links: {
                "topics" => [topic_content_id]
              }
            )
          end

          it "returns a hash with grouped results" do
            results = ::Queries::GetGroupedContentAndLinks.call
            presenter = Presenters::Queries::GroupedContentWithLinks.new(results)

            presented_results = presenter.present[:results]

            expect(presented_results).to eq(
              [
                {
                  content_id: content_id,
                  content_items: [
                    {
                      locale: "en",
                      base_path: "/such-base-path",
                      publishing_app: "whitehall",
                      format: "guide",
                      user_facing_version: "2",
                      state: "draft",
                    },
                    {
                      locale: "en",
                      base_path: "/such-base-path",
                      publishing_app: "whitehall",
                      format: "guide",
                      user_facing_version: "1",
                      state: "published",
                    },
                  ],
                  links: {
                    topics: [
                      {
                        content_id: topic_content_id,
                      }
                    ]
                  }
                }
              ]
            )
          end
        end
      end

    end
  end
end
