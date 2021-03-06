require "rails_helper"

RSpec.describe LockVersion do
  subject { FactoryGirl.build(:lock_version) }

  it "starts version numbers at 0" do
    content_item = FactoryGirl.create(:content_item)
    lock_version = LockVersion.create!(target: content_item)
    expect(lock_version.number).to be_zero
    expect(lock_version).to be_valid
  end

  describe "#conflicts_with?(previous_version_number)" do
    before do
      subject.number = 2
    end

    context "when the previous lock_version is lower than the current lock_version" do
      let(:previous_version_number) { subject.number - 1 }

      it "conflicts" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(true)
      end
    end

    context "when the previous lock_version matches the current lock_version number" do
      let(:previous_version_number) { subject.number }

      it "does not conflict" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(false)
      end
    end

    context "when the previous lock_version is larger than the current lock_version number" do
      let(:previous_version_number) { subject.number + 1 }

      it "conflicts, and something really weird is going on" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(true)
      end
    end

    context "when the previous lock_version is absent" do
      let(:previous_version_number) { nil }

      it "does not conflict" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(false)
      end
    end
  end

  describe "#increment" do
    it "adds one to the number" do
      subject.increment
      expect(subject.number).to eq(1)

      subject.increment
      expect(subject.number).to eq(2)
    end
  end

  describe "validations" do
    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }

    let!(:draft) do
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
        base_path: base_path,
        user_facing_version: 2,
      )
    end

    let!(:live) do
      FactoryGirl.create(:live_content_item,
        content_id: content_id,
        base_path: base_path,
        user_facing_version: 1,
      )
    end

    let(:draft_version) { described_class.find_by!(target: draft) }
    let(:live_version) { described_class.find_by!(target: live) }

    context "when the draft version is behind the live version" do
      before do
        draft_version.number = 1
        draft_version.save!(validate: false)

        live_version.number = 2
        live_version.save!(validate: false)
      end

      it "makes the draft version invalid" do
        expect(draft_version).to be_invalid

        expect(draft_version.errors[:number]).to include(
          "draft LockVersion cannot be behind the live LockVersion (1 < 2)"
        )
      end

      it "makes the live version invalid" do
        expect(live_version).to be_invalid

        expect(live_version.errors[:number]).to include(
          "draft LockVersion cannot be behind the live LockVersion (1 < 2)"
        )
      end
    end

    context "when the draft version is equal to the live version" do
      before do
        draft_version.number = 2
        live_version.number = 2
      end

      it "has a valid draft version" do
        expect(draft_version).to be_valid
      end

      it "has a valid live version" do
        draft_version.save!
        expect(live_version).to be_valid
      end
    end

    context "when the draft version is ahead of the live version" do
      before do
        draft_version.number = 3
        live_version.number = 2
      end

      it "has a valid draft version" do
        expect(draft_version).to be_valid
      end

      it "has a valid live version" do
        draft_version.save!
        expect(live_version).to be_valid
      end
    end
  end
end
