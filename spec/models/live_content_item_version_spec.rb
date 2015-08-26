require 'rails_helper'

RSpec.describe LiveContentItemVersion do
  describe ".latest_version" do
    let(:content_id) { "57747531-242f-46ae-83dc-51ff13dd2424" }

    context "no items" do
      it "returns nil" do
        expect(described_class.latest_version(content_id)).to eq(nil)
      end
    end

    context "one item" do
      before do
        described_class.create(version: 1, content_id: content_id, details: {})
      end

      it "returns the version of that item" do
        expect(described_class.latest_version(content_id)).to eq(1)
      end
    end

    context "two items" do
      before do
        described_class.create(version: 1, content_id: content_id, details: {})
        described_class.create(version: 2, content_id: content_id, details: {})
      end

      it "returns the latest version" do
        expect(described_class.latest_version(content_id)).to eq(2)
      end
    end
  end
end
