require "rails_helper"

RSpec.describe Queries::GetGroupedContentAndLinks do
  let(:ordered_content_ids) do
    %w(
      5f612a9f-7d3f-4b4c-a35e-ebd0b1e79019
      fd161210-3e12-41e7-8e5e-c8cef607a95f
    )
  end

  def new_content_item
    SecureRandom.uuid
  end

  describe "#call" do
    context "when no results exist" do
      it "returns an empty array" do
        expect(subject.call).to be_empty
      end
    end

    context "when no pagination is specified" do
      it "returns page with default page size" do
        FactoryGirl.create_list(:content_item, 12)
        expect(subject.call.size).to eql(subject::PAGE_SIZE)
      end
    end

    context "when retrieving the next page" do
      it "returns items after last seen" do
        item = FactoryGirl.create(
          :content_item,
          base_path: '/random',
          content_id: ordered_content_ids.first
        )

        item2 = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.last
        )

        results = subject.call(last_seen_content_id: item.content_id)

        expect(results.size).to eq(1)
        expect(results[0][:content_id]).to eql(item2.content_id)
      end
    end

    context "when there are documents" do
      before do
        FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.first,
          base_path: "/capital-gains-tax",
          state: "published"
        )
      end

      context "with no links" do
        it "returns the content item with empty links" do
          results = subject.call
          expect(results.size).to eq(1)
          expect(results[0]).to include(:links)
          expect(results[0][:links]).to eq([])
        end
      end

      context "with links" do
        let(:target_content_id) { SecureRandom.uuid }

        before do
          link_set = FactoryGirl.create(
            :link_set,
            content_id: ordered_content_ids.first,
            links: {
              "topics" => [
                target_content_id
              ]
            }
          )
        end

        it "returns the content item with links" do
          results = subject.call
          expect(results.size).to eq(1)
          expect(results[0]).to include(:links)
          expect(results[0][:links]).to eq(
            [
              {
                "content_id" => ordered_content_ids.first,
                "link_type"  => "topics",
                "target_content_id" => target_content_id,
              }
            ]
          )
        end
      end

      context "with multiple editions (draft & published)" do
        before do
          FactoryGirl.create(
            :content_item,
            content_id: ordered_content_ids.first,
            base_path: "/vat-rates",
            state: "published"
          )

          FactoryGirl.create(
            :content_item,
            content_id: ordered_content_ids.first,
            base_path: "/vat-rates",
            state: "draft"
          )

          FactoryGirl.create(
            :content_item,
            content_id: ordered_content_ids.last,
            base_path: "/register-to-vote",
            state: "published"
          )
        end

        context "with no links" do
          it "returns the content item with empty links" do
            results = subject.call

            expect(results.size).to eq(2)
            expect(results[0]).to include(:links)
            expect(results[0][:links]).to eq([])

            expect(results[1]).to include(:links)
            expect(results[1][:links]).to eq([])
          end
        end

        context "with links" do
          let(:first_target_content_id) { SecureRandom.uuid }
          let(:second_target_content_id) { SecureRandom.uuid }

          before do
            link_set1 = FactoryGirl.create(
              :link_set,
              links: {
                "topics" => [
                  first_target_content_id
                ]
              },
              content_id: ordered_content_ids.first
            )

            link_set2 = FactoryGirl.create(
              :link_set,
              links: {
                "topics" => [
                  second_target_content_id
                ]
              },
              content_id: ordered_content_ids.last
            )
          end

          it "returns the content item with links" do
            results = subject.call

            expect(results.size).to eq(2)
            expect(results[0]).to include(:links)
            expect(results[0][:links]).to eq([
              {
                "content_id" => ordered_content_ids.first,
                "link_type"  => "topics",
                "target_content_id" => first_target_content_id,
              }
            ])

            expect(results[1]).to include(:links)
            expect(results[1][:links]).to eq([
              {
                "content_id" => ordered_content_ids.last,
                "link_type"  => "topics",
                "target_content_id" => second_target_content_id,
              }
            ])
          end
        end
      end
    end
  end
end
