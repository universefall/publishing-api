require "rails_helper"

RSpec.describe Queries::GetLinked do
  item_content_id_1 = SecureRandom.uuid
  item_content_id_2 = SecureRandom.uuid

  describe "returning linked items" do


    it "when item of given content id does not exist, return error" do
      expect {
        subject.call("uuid-that-does-not-exist", "councils")
      }.to raise_error(CommandError)
    end

    it "when content item exists, and link of given type exists, returns array of items" do
      content_item_1 = FactoryGirl.create(:live_content_item, content_id: item_content_id_1, base_path: "/vat")
      content_item_2 = FactoryGirl.create(:live_content_item, content_id: item_content_id_2, base_path: "/pay-now")

      link = FactoryGirl.create(:link_set, content_id: item_content_id_1)
      link_1 = FactoryGirl.create(:link, link_set: link, link_type: "organisations", target_content_id: item_content_id_2)
      link_2 = FactoryGirl.create(:link, link_set: link, link_type: "related-links", target_content_id: "2222-2222-2222-2222")

      expect(subject.call(item_content_id_2, "organisations")).to eq([ link.to_json ])
    end

    it "when content item exists, and link of given type does not exist, returns an empty array" do
      content_item_1 = FactoryGirl.create(:live_content_item, content_id: item_content_id_1, base_path: "/vat")
      content_item_2 = FactoryGirl.create(:live_content_item, content_id: item_content_id_2, base_path: "/pay-now")

      link = FactoryGirl.create(:link_set, content_id: item_content_id_1)

      link_1 = FactoryGirl.create(:link, link_set: link, link_type: "organisations", target_content_id: item_content_id_2)

      expect(subject.call(item_content_id_2, "related-links")).to eq([ ])
    end

    it "endpoint accepts queries with parameters" do
      # do later
    end
  end
end
