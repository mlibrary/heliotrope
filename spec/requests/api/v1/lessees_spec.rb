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
  let(:new_lessee) { build(:lessee, id: lessee.id + 1, identifier: new_identifier) }
  let(:new_identifier) { 'new_lessee' }
  let(:lessee) { create(:lessee, identifier: identifier) }
  let(:identifier) { 'lessee' }
  let(:response_body) { JSON.parse(@response.body) }

  before { lessee }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { lessee: { identifier: new_identifier } } }

    it { get api_find_lessee_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_lessees_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_lessees_path, params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_lessee_path(lessee), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_lessee_path(lessee), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_find_lessee_path' do
      let(:params) { { identifier: new_identifier } }
      describe 'GET /api/v1/lessee' do
        it 'not found' do
          get api_find_lessee_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'found' do
          new_lessee.save
          get api_find_lessee_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).not_to be_empty
          expect(response_body).to eq(lessee_obj(lessee: new_lessee))
        end
      end
    end

    context 'api_v1_lessess_path' do
      describe "GET /api/v1/lessees" do # index
        it 'empty' do
          lessee.destroy!
          get api_lessees_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'lessee' do
          get api_lessees_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([lessee_obj(lessee: lessee)])
        end

        it 'lessees' do
          new_lessee.save!
          get api_lessees_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([lessee_obj(lessee: lessee), lessee_obj(lessee: new_lessee)])
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
            expect(Lessee.all.count).to eq(1)
          end
        end

        context 'unique identifier' do
          let(:params) { { lessee: { identifier: new_identifier } } }

          it 'creates lessee' do
            post api_lessees_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(new_identifier)
            expect(Lessee.find_by(identifier: new_identifier)).not_to be_nil
            expect(Lessee.all.count).to eq(2)
          end
        end

        context 'existing identifier' do
          let(:params) { { lessee: { identifier: identifier } } }

          it 'does nothing' do
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

    context 'api_v1_lessee_path' do
      describe "GET /api/v1/lessees/:id" do # show
        it 'does nothing' do
          get api_lessee_path(new_lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'returns lessee' do
          get api_lessee_path(lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(lessee_obj(lessee: lessee))
        end
      end

      describe "DELETE /api/v1/lessees/:id" do # destroy
        it 'does nothing' do
          delete api_lessee_path(new_lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Lessee.find_by(identifier: new_identifier)).to be_nil
          expect(Lessee.all.count).to eq(1)
        end

        it 'deletes lessee' do
          delete api_lessee_path(lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Lessee.find_by(identifier: identifier)).to be_nil
          expect(Lessee.all.count).to eq(0)
        end

        context 'lessee of product' do
          let(:product) { create(:product) }

          it 'does nothing' do
            lessee.products << product
            lessee.save!
            delete api_lessee_path(lessee), headers: headers
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
