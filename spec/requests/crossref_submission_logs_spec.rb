# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CrossrefSubmissionLogs", type: :request do
  let(:admin) { create(:platform_admin) }

  before { sign_in(admin) }

  describe "#index" do
    it do
      get crossref_submission_logs_path
      expect(response).to render_template(:index)
    end
  end

  describe "#show" do
    let(:log) { create(:crossref_submission_log, response_xml: "<xml>Hello there!</xml>") }

    context "with the correct file/field" do
      it do
        get crossref_submission_log_file_path(log.id, file: "response_xml")
        expect(response).to render_template(:show)
        expect(response.body).to match(/Hello there!/)
      end
    end

    context "with a weird/bad file/field" do
      it do
        get crossref_submission_log_file_path(log.id, file: "not_a_thing")
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
