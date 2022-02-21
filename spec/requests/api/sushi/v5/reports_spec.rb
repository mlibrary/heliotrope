# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Sushi Reports", type: :request do
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.sushi.v5+json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:id) { 'pr' }
  let(:params) { { customer_id: customer_id, platform: platform_id } }
  let(:customer_id) { 'customer_id' }
  let(:platform_id) { 'platform_id' }
  let(:current_user) { instance_double(User, 'current_user', id: 'id', email: 'platform_admin', platform_admin?: true) }
  let(:institution) { instance_double(Greensub::Institution, 'institution') }
  let(:press) { instance_double(Press, 'press') }
  let(:response_body) { JSON.parse(@response.body).map(&:deep_symbolize_keys!) }

  before do
    allow_any_instance_of(API::ApplicationController).to receive(:current_user).and_return(current_user)
    allow(User).to receive(:find).with(current_user.id).and_return(current_user)
    allow(Greensub::Institution).to receive(:find).with(customer_id).and_return(institution)
    allow(Press).to receive(:find).with(platform_id).and_return(press)
  end

  context 'unauthorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_raise(StandardError) }

    it { get api_sushi_report_path(id), params: params, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    it 'invalid report id' do
      expect { get api_sushi_report_path('id'), headers: headers }.to raise_error(StandardError)
    end

    it 'params customer_id missing' do
      get api_sushi_report_path(id), headers: headers
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_empty
    end

    context 'api_sushi_v5_report_path' do
      describe "GET /api/sushi/v5/reports/:id" do # show
        context 'database report' do
          let(:id) { 'dr' } # {:id=>/dr|dr_d1|dr_d2/}
          # let(:report) { SwaggerClient::COUNTERDatabaseReport.new(attributes) }

          it 'returns report' do
            get api_sushi_report_path(id), params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
            # expect(response_body).to eq(report.to_hash)
          end
        end

        context 'item report' do
          let(:id) { 'ir' } # {:id=>/ir|ir_a1|ir_m1/}
          # let(:report) { SwaggerClient::COUNTERItemReport.new(attributes) }

          it 'returns report' do
            get api_sushi_report_path(id), params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
            # expect(response_body).to eq(report.to_hash)
          end
        end

        context 'platform report' do
          let(:id) { 'pr' } # {:id=>/pr|pr_p1/}
          # let(:report) { SwaggerClient::COUNTERPlatformReport.new(attributes) }

          it 'returns report' do
            get api_sushi_report_path(id), params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
            # expect(response_body).to eq(report.to_hash)
          end
        end

        context 'title report' do
          let(:id) { 'tr' } # {:id=>/tr|tr_b1|tr_b2|tr_b3|tr_j1|tr_j2|tr_j3|tr_j4/}
          # let(:report) { SwaggerClient::COUNTERTitleReport.new(attributes) }

          it 'returns report' do
            get api_sushi_report_path(id), params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).not_to be_empty
            # expect(response_body).to eq(report.to_hash)
          end
        end
      end
    end
  end
end
