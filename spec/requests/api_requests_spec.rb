# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "APIRequests", type: :request do
  let(:api_request) { create(:api_request) }

  context 'anonymous' do
    describe "GET /api_requests" do
      it do
        get api_requests_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'user' do
    before { cosign_sign_in(current_user) }

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      describe "GET /api_requests" do
        it do
          get api_requests_path
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(presses_path)
        end
      end
    end

    context 'authorized' do
      let(:current_user) { create(:platform_admin) }

      describe "GET /api_requests" do
        it do
          get api_requests_path
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
