# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Institutions", type: :request do
  def institution_obj(institution:)
    {
      "id" => institution.id,
      "identifier" => institution.identifier,
      "name" => institution.name,
      "entity_id" => institution.entity_id,
      "url" => institution_url(institution, format: :json)
    }
  end

  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:new_institution) { build(:institution, id: institution.id + 1, name: new_name, identifier: new_identifier) }
  let(:new_name) { 'new_instituion' }
  let(:new_identifier) { 'new_identifier' }
  let(:institution) { create(:institution, name: name, identifier: identifier) }
  let(:name) { 'institution' }
  let(:identifier) { 'identifier' }
  let(:response_body) { JSON.parse(@response.body) }

  before { institution }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { institution: { name: new_name, identifier: new_identifier } } }

    it { get api_find_institution_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institutions_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_institutions_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_path(institution), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_institution_path(institution), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_institution_path(institution), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_find_institution_path' do
      let(:params) { { identifier: new_identifier } }

      describe 'GET /api/v1/institution' do
        it 'not found' do
          get api_find_institution_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'found' do
          new_institution.save
          get api_find_institution_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).not_to be_empty
          expect(response_body).to eq(institution_obj(institution: new_institution))
        end
      end
    end

    context 'api_v1_institutions_path' do
      describe "GET /api/v1/institutions" do # index
        it 'empty' do
          institution.destroy!
          get api_institutions_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'institution' do
          get api_institutions_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([institution_obj(institution: institution)])
        end

        it 'institutions' do
          new_institution.save
          get api_institutions_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([institution_obj(institution: institution), institution_obj(institution: new_institution)])
        end
      end
    end

    describe "POST /api/v1/institution" do # create
      let(:input) { params.to_json }

      context 'blank identifier' do
        let(:params) { { identifier: { identifier: '' } } }

        it 'errors' do
          post api_institutions_path, params: input, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
          expect(response_body[:name.to_s]).to eq(["can't be blank"])
          expect(Institution.all.count).to eq(1)
        end
      end

      context 'unique identifier AND name' do
        let(:params) { { institution: { identifier: new_identifier, name: new_name } } }

        it 'creates the institution' do
          post api_institutions_path, params: input, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:identifier.to_s]).to eq(new_identifier)
          expect(response_body[:name.to_s]).to eq(new_name)
          expect(Institution.find_by(identifier: new_identifier)).not_to be_nil
          expect(Institution.all.count).to eq(2)
          # an new institution also creates a lessee
          expect(Lessee.find_by(identifier: new_identifier)).not_to be_nil
        end
      end

      context 'existing identifier' do
        let(:params) { { institution: { identifier: identifier } } }

        it 'does nothing' do
          post api_institutions_path, params: input, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body[:identifier.to_s]).to eq(identifier)
          expect(Institution.find_by(identifier: identifier)).not_to be_nil
          expect(Institution.all.count).to eq(1)
        end
      end
    end

    context 'api_v1_institution_path' do
      describe "GET /api/v1/institution/:id" do # show
        it 'does nothing' do
          get api_institution_path(new_institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'returns institution' do
          get api_institution_path(institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(institution_obj(institution: institution))
        end
      end

      describe "PUT /api/v1/institution" do # update
        let(:params) { { institution: { identifier: identifier, name: 'updated_name' } } }

        it 'does not update nonexistent institutions' do
          put api_institution_path(new_institution.id), params: new_institution.to_json, headers: headers
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'updates' do
          put api_institution_path(institution.id), params: params.to_json, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body[:name.to_s]).to eq('updated_name')
        end
      end

      describe "DELETE /api/v1/institution/:id" do # destroy
        it 'does nothing' do
          delete api_institution_path(new_institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Institution.find_by(identifier: new_identifier)).to be_nil
          expect(Institution.all.count).to eq(1)
        end

        it 'deletes institution AND lessee' do
          delete api_institution_path(institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Institution.find_by(identifier: identifier)).to be_nil
          expect(Institution.all.count).to eq(0)
          expect(Lessee.find_by(identifier: identifier)).to be_nil
          expect(Lessee.all.count).to eq(0)
        end
      end
    end
  end
end
