# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Sushi Service", type: :request do
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.sushi.v5+json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:params) { { customer_id: 'customer_id', platform: 'platform_id' } }
  let(:institution) { instance_double(Greensub::Institution, 'institution', id: 'customer_id', name: 'Customer', entity_id: 'institution_entity_id') }
  let(:press) { instance_double(Press, 'press', id: 'platform_id', name: 'Platform') }
  let(:current_user) { instance_double(User, 'current_user', id: 'user_id', email: 'user_email', platform_admin?: true) }
  let(:response_body) { JSON.parse(@response.body).map(&:deep_symbolize_keys!) }

  before do
    allow_any_instance_of(API::ApplicationController).to receive(:current_user).and_return(current_user)
    allow(User).to receive(:find).with(current_user.id).and_return(current_user)
    allow(Greensub::Institution).to receive(:find).with(institution.id).and_return(institution)
    allow(Press).to receive(:find).with(press.id).and_return(press)
  end

  context 'unauthorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_raise(StandardError) }

    it { get api_sushi_path, headers: headers; expect(response).to have_http_status(:ok) } # rubocop:disable Style/Semicolon
    it { get api_sushi_status_path, params: params, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_sushi_members_path, params: params, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_sushi_reports_path, params: params, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_sushi_v5_status_path' do
      describe "GET /api/sushi/v5/status" do
        it 'params missing' do
          get api_sushi_status_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        context 'params' do
          it do
            get api_sushi_status_path, params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
          end
        end
      end
    end

    context 'api_sushi_v5_members_path' do
      describe "GET /api/sushi/v5/members" do
        it 'params missing' do
          get api_sushi_members_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        context 'params' do
          it do
            get api_sushi_members_path, params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
          end
        end
      end
    end

    context 'api_sushi_v5_reports_path' do
      describe "GET /api/sushi/v5/reports" do
        it 'params missing' do
          get api_sushi_reports_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        context 'params' do
          it do
            get api_sushi_reports_path, params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
          end
        end
      end
    end
  end
end
