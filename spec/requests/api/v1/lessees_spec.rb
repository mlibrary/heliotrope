# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessees", type: :request do
  def lessee_obj(lessee:)
    {
      "id" => lessee.id,
      "identifier" => lessee.identifier,
      "url" => lessee_url(lessee, format: :json)
    }
  end

  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:lessee) { create(:lessee, identifier: identifier) }
  let(:identifier) { 'lessee' }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { lessee: { identifier: identifier } } }

    it { get api_lessees_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_lessees_path, params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_lessee_path(identifier), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_lessee_path(identifier), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_vi_lessess_path' do
      describe "GET /api/v1/lessees" do # index
        it 'empty' do
          get api_lessees_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'lessee' do
          lessee
          get api_lessees_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([lessee_obj(lessee: lessee)])
        end

        it 'lessees' do
          lessee
          identifier2 = 'lessee2'
          lessee2 = create(:lessee, identifier: identifier2)
          get api_lessees_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([lessee_obj(lessee: lessee), lessee_obj(lessee: lessee2)])
        end
      end

      describe "POST /api/v1/lessees" do # create
        let(:input) { params.to_json }

        context 'blank identifier' do
          let(:params) { { lessee: { identifier: '' } } }

          it 'errors' do
            post api_lessees_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            expect(Lessee.all.count).to eq(0)
          end
        end

        context 'identifier' do
          let(:params) { { lessee: { identifier: identifier } } }

          it 'empty' do
            post api_lessees_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Lessee.find_by(identifier: identifier)).not_to be_nil
            expect(Lessee.all.count).to eq(1)
          end

          it 'exists' do
            lessee
            post api_lessees_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Lessee.find_by(identifier: identifier)).not_to be_nil
            expect(Lessee.all.count).to eq(1)
          end
        end
      end
    end

    context 'api_lessee_path' do
      describe "GET /api/v1/lessees/:identifier" do # show
        it 'empty' do
          get api_lessee_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'lessee' do
          lessee
          get api_lessee_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(lessee_obj(lessee: lessee))
        end
      end

      describe "DELETE /api/v1/lessees/:identifier" do # destroy
        it 'empty' do
          delete api_lessee_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Lessee.find_by(identifier: identifier)).to be_nil
          expect(Lessee.all.count).to eq(0)
        end

        it 'lessee' do
          lessee
          delete api_lessee_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Lessee.find_by(identifier: identifier)).to be_nil
          expect(Lessee.all.count).to eq(0)
        end

        context 'product' do
          let(:product) { create(:product) }

          it 'lessee of product' do
            lessee
            lessee.products << product
            lessee.save!
            delete api_lessee_path(identifier), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:accepted)
            expect(response.body).to be_empty
            expect(Lessee.find_by(identifier: identifier)).not_to be_nil
            expect(Lessee.all.count).to eq(1)
          end
        end
      end
    end
  end
end
