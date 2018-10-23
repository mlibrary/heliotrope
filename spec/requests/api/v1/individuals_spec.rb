# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Individuals", type: :request do
  def individual_obj(individual:)
    {
      "id" => individual.id,
      "identifier" => individual.identifier,
      "name" => individual.name,
      "email" => individual.email,
      "url" => individual_url(individual, format: :json)
    }
  end

  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:new_individual) { build(:individual, id: individual.id + 1, identifier: new_identifier, name: new_name, email: new_email) }
  let(:new_identifier) { 'new_identifier' }
  let(:new_name) { 'new_name' }
  let(:new_email) { 'new_email' }
  let(:individual) { create(:individual, identifier: identifier, name: name, email: email) }
  let(:identifier) { 'identifier' }
  let(:name) { 'name' }
  let(:email) { 'email' }
  let(:response_body) { JSON.parse(@response.body) }

  before { individual }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { individual: { name: new_name, identifier: new_identifier } } }

    it { get api_find_individual_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individuals_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_individuals_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individual_path(individual), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_individual_path(individual), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_individual_path(individual), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_find_individual_path' do
      let(:params) { { identifier: new_identifier } }

      describe 'GET /api/v1/individual' do
        it 'not found' do
          get api_find_individual_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'found' do
          new_individual.save
          get api_find_individual_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).not_to be_empty
          expect(response_body).to eq(individual_obj(individual: new_individual))
        end
      end
    end

    context 'api_v1_individuals_path' do
      describe "GET /api/v1/individuals" do # index
        it 'empty' do
          individual.destroy!
          get api_individuals_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'individual' do
          get api_individuals_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([individual_obj(individual: individual)])
        end

        it 'individuals' do
          new_individual.save
          get api_individuals_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([individual_obj(individual: individual), individual_obj(individual: new_individual)])
        end
      end
    end

    describe "POST /api/v1/individual" do # create
      let(:input) { params.to_json }

      context 'blank identifier' do
        let(:params) { { identifier: { identifier: '' } } }

        it 'errors' do
          post api_individuals_path, params: input, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
          expect(response_body[:email.to_s]).to eq(["can't be blank"])
          expect(Individual.all.count).to eq(1)
        end
      end

      context 'unique identifier AND name AND unique email' do
        let(:params) { { individual: { identifier: new_identifier, name: new_name, email: new_email } } }

        it 'creates the individual' do
          post api_individuals_path, params: input, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:identifier.to_s]).to eq(new_identifier)
          expect(response_body[:name.to_s]).to eq(new_name)
          expect(Individual.find_by(identifier: new_identifier)).not_to be_nil
          expect(Individual.all.count).to eq(2)
          # an new individual also creates a lessee
          # expect(Lessee.find_by(identifier: new_identifier)).not_to be_nil
        end
      end

      context 'existing identifier' do
        let(:params) { { individual: { identifier: identifier } } }

        it 'does nothing' do
          post api_individuals_path, params: input, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body[:identifier.to_s]).to eq(identifier)
          expect(Individual.find_by(identifier: identifier)).not_to be_nil
          expect(Individual.all.count).to eq(1)
        end
      end
    end

    context 'api_v1_individual_path' do
      describe "GET /api/v1/individual/:id" do # show
        it 'does nothing' do
          get api_individual_path(new_individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'returns individual' do
          get api_individual_path(individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(individual_obj(individual: individual))
        end
      end

      describe "DELETE /api/v1/individual/:id" do # destroy
        it 'does nothing' do
          delete api_individual_path(new_individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Individual.find_by(identifier: new_identifier)).to be_nil
          expect(Individual.all.count).to eq(1)
        end

        it 'deletes individual AND lessee' do
          delete api_individual_path(individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Individual.find_by(identifier: identifier)).to be_nil
          expect(Individual.all.count).to eq(0)
          expect(Lessee.find_by(identifier: identifier)).to be_nil
          expect(Lessee.all.count).to eq(0)
        end
      end

      describe "PUT /api/v1/individual" do # update
        let(:params) { { individual: { identifier: identifier, name: 'updated_name' } } }

        it 'does not update nonexistent individuals' do
          put api_individual_path(new_individual.id), params: new_individual.to_json, headers: headers
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'updates' do
          put api_individual_path(individual.id), params: params.to_json, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body[:name.to_s]).to eq('updated_name')
        end
      end
    end
  end
end
