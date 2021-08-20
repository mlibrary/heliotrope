# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Licenses", type: :request do
  def license_obj(license:)
    {
      "id" => license.id,
      "type" => license.type,
      "licensee_type" => license.licensee_type,
      "licensee_id" => license.licensee_id,
      "product_id" => license.product_id,
      "url" => greensub_license_url(license, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:individual_license) { create(:full_license, licensee: individual, product: product) }
  let(:institution_license) { create(:read_license, licensee: institution, product: product) }
  let(:individual) { create(:individual) }
  let(:institution) { create(:institution) }
  let(:product) { create(:product) }
  let(:response_body) { JSON.parse(@response.body) }

  before { clear_grants_table }

  context 'unauthorized' do
    it { get api_licenses_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_licenses_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individual_licenses_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_licenses_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_licenses_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_license_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_license_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_license_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe "GET /api/v1/licenses" do # index
      it 'empty ok' do
        get api_licenses_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::License.count).to eq(0)
      end

      it 'license ok' do
        individual_license
        get api_licenses_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: individual_license)])
        expect(Greensub::License.count).to eq(1)
      end

      it 'licenses ok' do
        individual_license
        institution_license
        get api_licenses_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: individual_license), license_obj(license: institution_license)])
        expect(Greensub::License.count).to eq(2)
      end
    end

    describe "GET /api/v1/product/:product_id/licenses" do # index
      it 'not_found' do
        get api_product_licenses_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product")
        expect(Greensub::License.count).to eq(0)
      end

      it 'empty ok' do
        get api_product_licenses_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::License.count).to eq(0)
      end

      it 'license ok' do
        individual_license
        get api_product_licenses_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: individual_license)])
        expect(Greensub::License.count).to eq(1)
      end

      it 'licenses ok' do
        individual_license
        institution_license
        get api_product_licenses_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: individual_license), license_obj(license: institution_license)])
        expect(Greensub::License.count).to eq(2)
      end
    end

    describe "GET /api/v1/individual/:individual_id/licenses" do # index
      it 'not_found' do
        get api_individual_licenses_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Individual")
        expect(Greensub::License.count).to eq(0)
      end

      it 'empty ok' do
        get api_individual_licenses_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::License.count).to eq(0)
      end

      it 'license ok' do
        individual_license
        get api_individual_licenses_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: individual_license)])
        expect(Greensub::License.count).to eq(1)
      end

      it 'licenses ok' do
        individual_license
        individual_license2 = create(:read_license, licensee: individual, product: product)
        get api_individual_licenses_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: individual_license), license_obj(license: individual_license2)])
        expect(Greensub::License.count).to eq(2)
      end
    end

    describe "GET /api/v1/institution/:institution_id/licenses" do # index
      it 'not_found' do
        get api_institution_licenses_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution")
        expect(Greensub::License.count).to eq(0)
      end

      it 'empty ok' do
        get api_institution_licenses_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::License.count).to eq(0)
      end

      it 'license ok' do
        institution_license
        get api_institution_licenses_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: institution_license)])
        expect(Greensub::License.count).to eq(1)
      end

      it 'licenses ok' do
        institution_license
        institution_license2 = create(:full_license, licensee: institution, product: product)
        get api_institution_licenses_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([license_obj(license: institution_license), license_obj(license: institution_license2)])
        expect(Greensub::License.count).to eq(2)
      end
    end

    describe "POST /api/v1/licenses" do # create
      let(:params) { { license: { type: type, licensee_type: licensee_type, licensee_id: licensee_id, product_id: product_id } }.to_json }

      context 'blank' do
        let(:type) { '' }
        let(:licensee_type) { '' }
        let(:licensee_id) { '' }
        let(:product_id) { '' }

        it 'unprocessable_entity' do
          post api_licenses_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body['product']).to eq(["must exist"])
          expect(response_body['type']).to eq(["can't be blank", "is not included in the list"])
          expect(response_body['licensee_type']).to eq(["can't be blank", "is not included in the list"])
          expect(response_body['licensee_id']).to eq(["can't be blank"])
          expect(response_body['product_id']).to eq(["can't be blank"])
          expect(response_body['exception']).to eq(["Validation failed: Product must exist, Type can't be blank, Type is not included in the list, Licensee type can't be blank, Licensee type is not included in the list, Licensee can't be blank, Product can't be blank"])
          expect(Greensub::License.all.count).to eq(0)
        end
      end

      context 'non existing' do
        let(:type) { 'Greensub::FullLicense' }
        let(:licensee_type) { 'Greensub::Individual' }
        let(:licensee_id) { individual.id }
        let(:product_id) { product.id }

        it 'created' do
          post api_licenses_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:type.to_s]).to eq(type)
          expect(response_body[:licensee_type.to_s]).to eq(licensee_type)
          expect(response_body[:licensee_id.to_s]).to eq(licensee_id)
          expect(response_body[:product_id.to_s]).to eq(product_id)
          expect(Greensub::License.count).to eq(1)
        end
      end

      context 'existing' do
        let(:type) { 'Greensub::FullLicense' }
        let(:licensee_type) { 'Greensub::Individual' }
        let(:licensee_id) { individual.id }
        let(:product_id) { product.id }

        it 'unprocessable_entity' do
          post api_licenses_path, params: params, headers: headers
          post api_licenses_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:type.to_s]).to eq(type)
          expect(response_body[:licensee_type.to_s]).to eq(licensee_type)
          expect(response_body[:licensee_id.to_s]).to eq(licensee_id)
          expect(response_body[:product_id.to_s]).to eq(product_id)
          expect(Greensub::License.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/licenses/:id" do # show
      it 'non existing not_found' do
        get api_license_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::License")
        expect(Greensub::License.count).to eq(0)
      end

      it 'existing ok' do
        get api_license_path(individual_license), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(license_obj(license: individual_license))
        expect(Greensub::License.count).to eq(1)
      end
    end

    describe "PUT /api/v1/licenses/:id" do # update
      it 'non existing not_found' do
        put api_license_path(1), params: { license: { type: 'Greensub::ReadLicense' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::License")
        expect(Greensub::License.count).to eq(0)
      end

      it 'existing ok' do
        put api_license_path(individual_license), params: { license: { type: 'Greensub::ReadLicense' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body[:id.to_s]).to eq(individual_license.id)
        expect(response_body[:type.to_s]).to eq('Greensub::ReadLicense')
        expect(Greensub::License.count).to eq(1)
      end

      it 'existing update identifier unprocessable_entity' do
        new_product = create(:product)
        put api_license_path(individual_license), params: { license: { product_id: new_product.id } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).not_to have_http_status(:unprocessable_entity)
        expect(response_body[:product.to_s]).not_to eq(["can not be changed!"])
        expect(Greensub::License.count).to eq(1)
      end
    end

    describe "DELETE /api/v1/licenses/:id" do # destroy
      it 'non existing not_found' do
        delete api_license_path(individual_license.id + 1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::License")
        expect(Greensub::License.count).to eq(1)
      end

      it 'existing without affiliations ok' do
        delete api_license_path(institution_license), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
        expect(Greensub::License.count).to eq(0)
      end

      it 'existing with an affiliation accepted' do
        institution_license.affiliations << build(:license_affiliation)
        institution_license.save
        delete api_license_path(institution_license), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:accepted)
        expect(response_body[:base.to_s]).to include("Cannot delete record because dependent license affiliations exist")
        expect(Greensub::License.count).to eq(1)
      end

      it 'existing with backing grant accepted' do
        Authority.grant!(Authority.agent(institution_license.licensee.agent_type, institution_license.licensee.agent_id),
                         Authority.credential(institution_license.credential_type, institution_license.credential_id),
                         Authority.resource(institution_license.product.resource_type, institution_license.product.resource_id))
        delete api_license_path(institution_license), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:accepted)
        expect(response_body[:base.to_s]).to include("Cannot delete record because dependent grant exist")
        expect(Greensub::License.count).to eq(1)
        clear_grants_table
      end
    end
  end
end
