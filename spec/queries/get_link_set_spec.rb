require "rails_helper"

RSpec.describe Queries::GetLinkSet do
  it "returns the link set for a given content_id" do
    create_link_set(content_id: "foo")

    expect(subject.call("foo").fetch(:content_id)).to eq("foo")
  end

  it "returns the version of the link set" do
    create_link_set(content_id: "foo")

    expect(subject.call("foo").fetch(:version)).to eq(2)
  end

  context "when the link set does not exist" do
    it "returns an error object" do
      expect {
        subject.call("missing")
      }.to raise_error(CommandError, /with content_id: missing/)
    end
  end

  def create_link_set(content_id:)
    foo = create(:link_set, content_id: content_id)
    create(:version, target: foo, number: 2)
    create(:link_set, content_id: "bar")
  end
end
