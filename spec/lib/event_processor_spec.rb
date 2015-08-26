require 'rails_helper'

RSpec.describe EventProcessor do
  subject { described_class.new }

  let(:event_name) {
    "create_draft"
  }

  let(:event_payload) {
    {
      "title" => "Get Britain Building: Carlisle Park",
      "description" => "Nearly 400 homes...",
      "body" => "# Heading\n\nParagraph body.",
      "first_public_at" => "2012-12-17T15:45:44+00:00",
      "locale" => "en",
      "need_ids" => [],
      "public_updated_at" => "2012-12-17T15:45:44.000+00:00",
      "updated_at" => "2014-11-17T14:19:42.460Z"
    }
  }

  describe '#process' do
    it "records the event" do
      subject.process(event_name, event_payload)

      expect(Event.count).to eq(1)

      event = Event.first
      expect(event.name).to eq(event_name)
      expect(event.payload).to eq(event_payload)
    end

    it "returns the event" do
      event = subject.process(event_name, event_payload)

      expect(Event.first).to eq(event)
    end

    context "with a registered event handler" do
      let(:handler) { double("handler", call: true) }

      before do
        subject.register_event_handler(event_name, handler)
      end

      it "invokes any registered event handlers" do
        subject.process(event_name, event_payload)

        expect(handler).to have_received(:call).with(Event.first)
      end

      it "does not persist the event if the event handler raises an exception" do
        allow(handler).to receive(:call).and_raise

        begin
          subject.process(event_name, event_payload)
        rescue
        end

        expect(Event.count).to eq(0)
      end
    end
  end
end
