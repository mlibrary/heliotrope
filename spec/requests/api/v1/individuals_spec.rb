# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Individuals", type: :request do
  def individual_obj(individual:)
    {
      "id" => individual.id,
      "identifier" => individual.identifier,
      "name" => individual.name,
      "email" => individual.email,
      "url" => greensub_individual_url(individual, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:individual) { create(:individual) }
  let(:response_body) { JSON.parse(@response.body) }

  before { clear_grants_table }

  context 'unauthorized' do
    it { get api_find_individual_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individuals_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_individuals_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_individuals_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individual_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_individual_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_individual_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_product_individual_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_individual_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_individual_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_individual_license_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_product_individual_license_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe 'GET /api/v1/individual' do
      it 'non existing not_found' do
        get api_find_individual_path, params: { identifier: 'identifier' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Greensub::Individual.count).to eq(0)
      end

      it 'existing ok' do
        get api_find_individual_path, params: { identifier: individual.identifier }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(individual_obj(individual: individual))
        expect(Greensub::Individual.count).to eq(1)
      end
    end

    describe "GET /api/v1/individuals" do # index
      it 'empty ok' do
        get api_individuals_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::Individual.count).to eq(0)
      end

      it 'individual ok' do
        individual
        get api_individuals_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([individual_obj(individual: individual)])
        expect(Greensub::Individual.count).to eq(1)
      end

      it 'individuals ok' do
        individual
        new_individual = create(:individual)
        get api_individuals_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to match_array([individual_obj(individual: individual), individual_obj(individual: new_individual)])
        expect(Greensub::Individual.count).to eq(2)
      end
    end

    describe "GET /api/v1/products/:product_id/individuals" do # index
      let(:product) { create(:product) }
      let(:individual_response_body) { JSON.parse(@response.body) }
      let(:individuals_response_body) { JSON.parse(@response.body) }

      it 'empty ok' do
        get api_product_individuals_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::Individual.count).to eq(0)
      end

      it 'individual ok' do
        individual
        get api_product_individuals_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        put api_product_individual_path(product, individual), headers: headers
        get api_product_individuals_path(product), headers: headers
        expect(individual_response_body).to eq([individual_obj(individual: individual)])
        expect(Greensub::Individual.count).to eq(1)
      end

      it 'individuals ok' do
        individual
        new_individual = create(:individual)
        get api_product_individuals_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        put api_product_individual_path(product, individual), headers: headers
        get api_product_individuals_path(product), headers: headers
        expect(individual_response_body).to eq([individual_obj(individual: individual)])
        put api_product_individual_path(product, new_individual), headers: headers
        get api_product_individuals_path(product), headers: headers
        expect(individuals_response_body).to match_array([individual_obj(individual: individual), individual_obj(individual: new_individual)])
        expect(Greensub::Individual.count).to eq(2)
      end
    end

    describe "POST /api/v1/individuals" do # create
      let(:params) { { individual: { identifier: identifier, name: name, email: email } }.to_json }

      context 'blank' do
        let(:identifier) { '' }
        let(:name) { '' }
        let(:email) { '' }

        it 'unprocessable_entity' do
          post api_individuals_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
          expect(response_body[:name.to_s]).to eq(["can't be blank"])
          expect(response_body[:email.to_s]).to eq(["can't be blank"])
          expect(Greensub::Individual.count).to eq(0)
        end
      end

      context 'non existing' do
        let(:identifier) { 'identifier' }
        let(:name) { 'name' }
        let(:email) { 'email' }

        it 'created' do
          post api_individuals_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:identifier.to_s]).to eq(identifier)
          expect(response_body[:name.to_s]).to eq(name)
          expect(response_body[:email.to_s]).to eq(email)
          expect(Greensub::Individual.count).to eq(1)
        end
      end

      context 'existing' do
        let(:identifier) { individual.identifier }
        let(:name) { 'name' }
        let(:email) { 'email' }

        it 'unprocessable_entity' do
          post api_individuals_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["individual identifier #{identifier} exists!"])
          expect(Greensub::Individual.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/individual/:id" do # show
      it 'non existing not_found' do
        get api_individual_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual")
        expect(Greensub::Individual.count).to eq(0)
      end

      it 'existing ok' do
        get api_individual_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(individual_obj(individual: individual))
        expect(Greensub::Individual.count).to eq(1)
      end
    end

    describe "GET /api/v1/products/:product_id:/individuals/:id" do # show
      context 'non existing product' do
        it 'non existing individual not_found' do
          get api_product_individual_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual not_found' do
          get api_product_individual_path(1, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing individual not_found' do
          get api_product_individual_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual ok' do
          individual.update_product_license(product)
          get api_product_individual_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(individual_obj(individual: individual))
          expect(product.individuals).to include(individual)
          expect(product.individuals.count).to eq(1)
        end
      end
    end

    describe "PUT /api/v1/individual" do # update
      it 'non existing not_found' do
        put api_individual_path(1), params: { individual: { name: 'updated_name' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual")
      end

      it 'existing ok' do
        put api_individual_path(individual.id), params: { individual: { name: 'updated_name' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body[:id.to_s]).to eq(individual.id)
        expect(response_body[:name.to_s]).to eq('updated_name')
      end

      it 'existing update identifier unprocessable_entity' do
        put api_individual_path(individual.id), params: { individual: { identifier: 'updated_identifier' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:identifier.to_s]).to eq(["individual identifier can not be changed!"])
      end
    end

    describe "PUT /api/v1/products/:product_id:/individuals/:id" do # update
      context 'non existing product' do
        it 'non existing individual not_found' do
          put api_product_individual_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual not_found' do
          put api_product_individual_path(1, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing individual not_found' do
          put api_product_individual_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual ok' do
          put api_product_individual_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(individual.product_license?(product)).to be true
        end

        it 'existing individual twice ok' do
          individual.update_product_license(product)
          put api_product_individual_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(individual.product_license?(product)).to be true
          expect(grants_table_count).to eq(1)
        end
      end
    end

    describe "DELETE /api/v1/individual/:id" do # destroy
      let(:product) { create(:product) }

      it 'non existing not_found' do
        delete api_individual_path(individual.id + 1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual")
        expect(Greensub::Individual.count).to eq(1)
      end

      it 'existing without products ok' do
        delete api_individual_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
        expect(Greensub::Individual.count).to eq(0)
      end

      it 'existing with products accepted' do
        individual.update_product_license(product)
        delete api_individual_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:accepted)
        expect(response_body[:base.to_s]).to include("individual has associated grant!")
        expect(Greensub::Individual.count).to eq(1)
      end
    end

    describe "DELETE /api/v1/products/:product_id:/individuals/:id" do # delete
      context 'non existing product' do
        it 'non existing individual not_found' do
          delete api_product_individual_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual not_found' do
          delete api_product_individual_path(1, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing individual not_found' do
          delete api_product_individual_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual ok' do
          individual.update_product_license(product)
          expect(individual.product_license?(product)).to be true
          delete api_product_individual_path(product, individual), headers: headers
          expect(individual.product_license?(product)).to be false
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Greensub::Individual.count).to eq(1)
        end

        it 'existing individual non subscriber ok' do
          expect(individual.product_license?(product)).to be false
          delete api_product_individual_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Greensub::Individual.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/products/:product_id:/individuals/:id/license" do # get license
      context 'non existing product' do
        it 'non existing individual not_found' do
          get api_product_individual_license_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual not_found' do
          get api_product_individual_license_path(1, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing individual not_found' do
          get api_product_individual_license_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual, no license, not_found' do
          get api_product_individual_license_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body).to eq({ "license"=>"undefined" })
        end

        it 'existing individual with full license ok' do
          individual.update_product_license(product)
          get api_product_individual_license_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq({ "license"=>"full" })
        end

        it 'exisiting individual with read license ok' do
          individual.update_product_license(product, license_type: "Greensub::ReadLicense")
          get api_product_individual_license_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq({ "license"=>"read" })
        end

        it 'exisiting individual with none/empty license ok' do
          individual.update_product_license(product, license_type: "Greensub::License")
          get api_product_individual_license_path(product, individual), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq({ "license"=>"none" })
        end
      end
    end

    describe "POST /api/v1/products/:product_id:/individuals/:id/license" do # set license
      context 'non existing product' do
        it 'non existing individual not_found' do
          post api_product_individual_license_path(1, 1), headers: headers, params: { license: 'full' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual not_found' do
          post api_product_individual_license_path(1, individual), headers: headers, params: { license: 'full' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing individual not_found' do
          post api_product_individual_license_path(product, 1), headers: headers, params: { license: 'full' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual with")
        end

        it 'existing individual setting full license ok' do
          post api_product_individual_license_path(product, individual), headers: headers, params: { license: 'full' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq({ "license"=>"full" })
          expect(individual.products.include?(product)).to be true
        end

        it 'existing individual setting read license ok' do
          post api_product_individual_license_path(product, individual), headers: headers, params: { license: 'read' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq({ "license"=>"read" })
          expect(individual.products.include?(product)).to be true
        end

        it 'existing individual setting a none/empty license ok' do
          post api_product_individual_license_path(product, individual), headers: headers, params: { license: 'none' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq({ "license"=>"none" })
          expect(individual.products.include?(product)).to be true
        end

        it 'existing individual setting a bad license unprocessable_entity' do
          post api_product_individual_license_path(product, individual), headers: headers, params: { license: 'bad' }.to_json
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:exception.to_s]).to include("no license type found for: bad")
          expect(individual.products.include?(product)).to be false
        end
      end
    end
  end
end
