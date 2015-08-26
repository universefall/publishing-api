require 'rails_helper'

RSpec.describe Services do
  subject(:services) { described_class.new }

  describe "event_processor" do
    subject { services.event_processor }

    it "can create a draft" do
      subject.process("create_draft", {})
      expect(DraftContentItem.count).to eq(1)
    end

  end
end
