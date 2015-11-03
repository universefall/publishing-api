require 'rails_helper'

RSpec.describe LinkPopulator do

  let!(:target_content_id_1) { SecureRandom.uuid }
  let!(:target_content_id_2) { SecureRandom.uuid }

  describe "adding linked items with same key" do
    it "creates 2 linked items with same link_type" do
      links = { organisations: [ target_content_id_1, target_content_id_2 ] }
      link_set = FactoryGirl.create(:link_set)

      LinkPopulator.create_or_replace(link_set, links)

      first_link = Link.find_by(target_content_id: target_content_id_1)
      second_link = Link.find_by(target_content_id: target_content_id_2)

      expect(first_link.link_set).to eq link_set
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target_content_id).to eq target_content_id_1

      expect(second_link.link_set).to eq link_set
      expect(second_link.link_type).to eq "organisations"
      expect(second_link.target_content_id).to eq target_content_id_2
    end
  end

  describe "adding linked items with different keys" do
    it "creates 2 linked items with different link_type" do
      links = {
        organisations: [ target_content_id_1 ],
        related_links: [ target_content_id_2 ],
      }
      link_set = FactoryGirl.create(:link_set)

      LinkPopulator.create_or_replace(link_set, links)

      first_link = Link.find_by(target_content_id: target_content_id_1)
      second_link = Link.find_by(target_content_id: target_content_id_2)

      expect(first_link.link_set).to eq link_set
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target_content_id).to eq target_content_id_1


      expect(second_link.link_set).to eq link_set
      expect(second_link.link_type).to eq "related_links"
      expect(second_link.target_content_id).to eq target_content_id_2
    end
  end

  describe "adding the same set of linked items twice" do
    it "copies are not stored to the database" do
      links = {
        organisations: [ target_content_id_1 ],
        related_links: [ target_content_id_2 ],
      }
      link_set = FactoryGirl.create(:link_set)

      LinkPopulator.create_or_replace(link_set, links)
      LinkPopulator.create_or_replace(link_set, links)

      first_link = Link.find_by(target_content_id: target_content_id_1)
      second_link = Link.find_by(target_content_id: target_content_id_2)

      expect(first_link.link_set).to eq link_set
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target_content_id).to eq target_content_id_1


      expect(second_link.link_set).to eq link_set
      expect(second_link.link_type).to eq "related_links"
      expect(second_link.target_content_id).to eq target_content_id_2

      expect(Link.all.count).to eq 2
    end
  end

  describe "updating an existent set of linked items" do
    let!(:first_set) {
      {
        organisations: [ target_content_id_1 ],
        related_links: [ target_content_id_2 ],
      }
    }
    it "updates the links when the keys are different" do
      second_set = {
        organisations: [ target_content_id_1, target_content_id_2 ],
      }
      link_set = FactoryGirl.create(:link_set)

      LinkPopulator.create_or_replace(link_set, first_set)
      LinkPopulator.create_or_replace(link_set, second_set)

      first_link = Link.find_by(target_content_id: target_content_id_1)
      second_link = Link.find_by(target_content_id: target_content_id_2)

      expect(first_link.link_set).to eq link_set
      expect(first_link.link_type).to eq "organisations"
      expect(first_link.target_content_id).to eq target_content_id_1


      expect(second_link.link_set).to eq link_set
      expect(second_link.link_type).to eq "organisations"
      expect(second_link.target_content_id).to eq target_content_id_2

      expect(Link.all.count).to eq 2
    end

    it "deletes the links when an empty set of links is provided" do
      second_set = {}
      link_set = FactoryGirl.create(:link_set)

      LinkPopulator.create_or_replace(link_set, first_set)

      expect(Link.all.count).to eq 2

      LinkPopulator.create_or_replace(link_set, second_set)

      expect(Link.all.count).to eq 0
    end

    it "deletes the links when `nil` provided instead of links" do
      second_set = nil
      link_set = FactoryGirl.create(:link_set)

      LinkPopulator.create_or_replace(link_set, first_set)

      expect(Link.all.count).to eq 2

      LinkPopulator.create_or_replace(link_set, second_set)

      expect(Link.all.count).to eq 0
    end
  end
end
