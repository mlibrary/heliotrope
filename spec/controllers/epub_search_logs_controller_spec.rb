# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe EpubSearchLogsController, type: :controller do
  let(:user) { create(:platform_admin) }

  describe "GET #index" do
    before do
      sign_in user
    end

    it "returns a response" do
      epub_search_log = EpubSearchLog.create!(noid: "999999999", query: "dog", time: 54, search_results: "2", user: "noone@fulcrum.org", press: "michigan", created_at: 1.day.ago, updated_at: 1.day.ago)
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:epub_search_logs)).to eq ([epub_search_log])
      expect(assigns(:csv_url)).to eq "http://test.host/epub_search_logs.csv"
    end
  end
end
