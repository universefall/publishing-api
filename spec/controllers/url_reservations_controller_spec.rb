require 'rails_helper'

RSpec.describe UrlReservationsController, type: :controller do
  describe "reserve_url" do
    context "with a valid url reservation request" do
      let(:payload) {
        { publishing_app: "Foo" }
      }

      it "responds successfully" do
        request.env["RAW_POST_DATA"] = payload.to_json
        post :reserve_url, base_path: "foo"

        expect(response.status).to eq(200)
      end
    end

    context "with an invalid url reservation request" do
      let(:payload) {
        { publishing_app: nil }
      }

      it "responds with status 422" do
        request.env["RAW_POST_DATA"] = payload.to_json
        post :reserve_url, base_path: "///"

        expect(response.status).to eq(422)
      end
    end
  end

end
