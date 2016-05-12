require "rails_helper"

RSpec.describe Queries::GetGroupedContentAndLinks do
  let(:ordered_content_ids) do
    %w(
      5f612a9f-7d3f-4b4c-a35e-ebd0b1e79019
      fd161210-3e12-41e7-8e5e-c8cef607a95f
    )
  end

  def create_content_items(quantity, options = {})
    1.upto(quantity) do |item|
      FactoryGirl.create(:content_item, options)
    end
  end

  describe "#call" do
    context "when no results exist" do
      it "returns an empty array" do
        create_content_items(5)
        expect(subject.call).to be_empty
      end
    end

    context "when no pagination is specified" do
      it "returns page with default page size" do
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

        expect(subject.call(last_seen_content_id: item.content_id).size).to eq(1)

        expect(
          subject.call(last_seen_content_id: item.content_id)[0]["content_id"]
        ).to eql(item2.content_id)
      end
    end

    context "when there is a published document with no links" do
      it "returns the document once, with one content item and empty links" do
        published_doc_1 = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.first,
          state: "published"
        )
        results = subject.call

        expect(results.size).to eq(1)
        expect(results.first).to eq nil
      end
    end

    context "when there is a document with multiple editions and no links" do
      it "returns the document once, with the correct number of content items and empty links" do
        published_doc_1 = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.first,
          base_path: "/vat-rates",
          state: "published"
        )

        draft_doc_1 = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.first,
          base_path: "/vat-rates",
          state: "draft"
        )

        published_doc_2 = FactoryGirl.create(
          :content_item,
          content_id: ordered_content_ids.last,
          base_path: "/register-to-vote",
          state: "published"
        )

        results = subject.call

        expect(results.size).to eq(2)
        expect(results.first).to eq nil
        expect(results.last).to eq nil
      end
    end

    context "when there is a document with multiple editions and multiple links" do
      it "returns the document once, with the correct number of content items and the correct number of links" do
        expect(true).to be_falsey
      end
    end
  end
end
