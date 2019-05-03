# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CrossrefRegistrations", type: :request do
  context "unauthorized" do
    it do
      post api_crossref_register_path, params: {}
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'authorized' do
    before do
      allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil)
      allow(Crossref::Register).to receive(:new).and_return(register)
    end

    describe "POST /api/crossref_register" do
      let(:register) { double("register", post: resp) }

      context "with bad parameters" do
        let(:params) { { fname: "<xml>Should be a file, not a string</xml>" } }
        let(:resp) { double("resp", code: 200, body: "we won't get this far before failure") }

        it "falls through the API::ApplicationController's rescue" do
          post api_crossref_register_path, params: params
          expect(response).to have_http_status(:unauthorized)
          expect(response.body).to match(/NoMethodError: undefined method `read/)
        end
      end

      context "with good parameters" do
        let(:params) { { fname: Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec', 'fixtures', 'fake_crossref_submit.xml'))) } }

        context "the correct response from crossref" do
          let(:resp) { double("resp", code: 200, body: "\n\n\n\n<html>\n<head><title>SUCCESS</title>\n</head>\n<body>\n<h2>SUCCESS</h2>\n<p>Your batch submission was successfully received.</p>\n</body>\n</html>\n") }

          it "returns success" do
            post api_crossref_register_path, params: params
            expect(response).to have_http_status(:ok)
            expect(response.body).to match(/SUCCESS/)
          end
        end

        context "a failed response from crossref" do
          # Crossref will respond with 200 even if there are problems.
          # Not always I think, but often.
          let(:resp) { double("resp", code: 200, body: "<html></head><title>Crossref Administration Home Page</title></head><body>some buried error message</body></html>") }

          it "returns error" do
            post api_crossref_register_path, params: params
            expect(response).to have_http_status(:bad_request)
            expect(response.body).not_to match(/SUCCESS/)
          end
        end
      end
    end
  end
end
