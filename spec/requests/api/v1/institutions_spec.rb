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
  let(:institution) { create(:institution) }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it { get api_find_institution_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institutions_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_institutions_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_institutions_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_institution_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_institution_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_product_institution_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_institution_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_institution_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe 'GET /api/v1/institution' do
      it 'non existing not_found' do
        get api_find_institution_path, params: { identifier: 'identifier' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Institution.count).to eq(0)
        expect(Lessee.count).to eq(0)
      end

      it 'existing ok' do
        get api_find_institution_path, params: { identifier: institution.identifier }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(institution_obj(institution: institution))
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end
    end

    describe "GET /api/v1/institutions" do # index
      it 'empty ok' do
        get api_institutions_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Institution.count).to eq(0)
        expect(Lessee.count).to eq(0)
      end

      it 'institution ok' do
        institution
        get api_institutions_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([institution_obj(institution: institution)])
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end

      it 'institutions ok' do
        institution
        new_institution = create(:institution)
        get api_institutions_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to match_array([institution_obj(institution: institution), institution_obj(institution: new_institution)])
        expect(Institution.count).to eq(2)
        expect(Lessee.count).to eq(2)
      end
    end

    describe "GET /api/v1/products/:product_id/institutions" do # index
      let(:product) { create(:product) }
      let(:institution_response_body) { JSON.parse(@response.body) }
      let(:institutions_response_body) { JSON.parse(@response.body) }

      it 'empty ok' do
        get api_product_institutions_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Institution.count).to eq(0)
        expect(Lessee.count).to eq(0)
      end

      it 'institution ok' do
        institution
        get api_product_institutions_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        put api_product_institution_path(product, institution), headers: headers
        get api_product_institutions_path(product), headers: headers
        expect(institution_response_body).to eq([institution_obj(institution: institution)])
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end

      it 'institutions ok' do
        institution
        new_institution = create(:institution)
        get api_product_institutions_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        put api_product_institution_path(product, institution), headers: headers
        get api_product_institutions_path(product), headers: headers
        expect(institution_response_body).to eq([institution_obj(institution: institution)])
        put api_product_institution_path(product, new_institution), headers: headers
        get api_product_institutions_path(product), headers: headers
        expect(institutions_response_body).to match_array([institution_obj(institution: institution), institution_obj(institution: new_institution)])
        expect(Institution.count).to eq(2)
        expect(Lessee.count).to eq(2)
      end
    end

    describe "POST /api/v1/institutions" do # create
      let(:params) { { institution: { identifier: identifier, name: name, entity_id: entity_id } }.to_json }

      context 'blank' do
        let(:identifier) { '' }
        let(:name) { '' }
        let(:entity_id) { '' }

        it 'unprocessable_entity' do
          post api_institutions_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
          expect(response_body[:name.to_s]).to eq(["can't be blank"])
          expect(response_body[:entity_id.to_s]).to be nil
          expect(Institution.count).to eq(0)
          expect(Lessee.count).to eq(0)
        end
      end

      context 'non existing' do
        let(:identifier) { 'identifier' }
        let(:name) { 'name' }
        let(:entity_id) { 'entity_id' }

        it 'created' do
          post api_institutions_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:identifier.to_s]).to eq(identifier)
          expect(response_body[:name.to_s]).to eq(name)
          expect(response_body[:entity_id.to_s]).to eq(entity_id)
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end
      end

      context 'existing' do
        let(:identifier) { institution.identifier }
        let(:name) { 'name' }
        let(:entity_id) { 'entity_id' }

        it 'unprocessable_entity' do
          post api_institutions_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["institution identifier #{identifier} exists!"])
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/institution/:id" do # show
      it 'non existing not_found' do
        get api_institution_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution")
        expect(Institution.count).to eq(0)
        expect(Lessee.count).to eq(0)
      end

      it 'existing ok' do
        get api_institution_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(institution_obj(institution: institution))
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end
    end

    describe "GET /api/v1/products/:product_id:/institutions/:id" do # show
      context 'non existing product' do
        it 'non existing institution not_found' do
          get api_product_institution_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution with")
          expect(Institution.count).to eq(0)
        end

        it 'existing institution not_found' do
          get api_product_institution_path(1, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Product with")
          expect(Institution.count).to eq(1)
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing institution not_found' do
          get api_product_institution_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution with")
          expect(Institution.count).to eq(0)
        end

        it 'existing institution ok' do
          put api_product_institution_path(product, institution), headers: headers
          get api_product_institution_path(product, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(institution_obj(institution: institution))
          expect(product.institutions).to include(institution)
          expect(product.institutions.count).to eq(1)
          expect(Institution.count).to eq(1)
        end
      end
    end

    describe "PUT /api/v1/institution" do # update
      it 'non existing not_found' do
        put api_institution_path(1), params: { institution: { name: 'updated_name' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution")
        expect(Institution.count).to eq(0)
        expect(Lessee.count).to eq(0)
      end

      it 'existing ok' do
        put api_institution_path(institution.id), params: { institution: { name: 'updated_name' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body[:id.to_s]).to eq(institution.id)
        expect(response_body[:name.to_s]).to eq('updated_name')
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end

      it 'existing update identifier unprocessable_entity' do
        put api_institution_path(institution.id), params: { institution: { identifier: 'updated_identifier' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:identifier.to_s]).to eq(["institution identifier can not be changed!"])
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end
    end

    describe "PUT /api/v1/products/:product_id:/institutions/:id" do # update
      context 'non existing product' do
        it 'non existing institution not_found' do
          put api_product_institution_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution with")
          expect(Institution.count).to eq(0)
          expect(Lessee.count).to eq(0)
        end

        it 'existing institution not_found' do
          put api_product_institution_path(1, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Product with")
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing institution not_found' do
          put api_product_institution_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution with")
          expect(Institution.count).to eq(0)
          expect(Lessee.count).to eq(0)
        end

        it 'existing institution ok' do
          put api_product_institution_path(product, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.lessees).to include(institution.lessee)
          expect(product.lessees.count).to eq(1)
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end

        it 'existing institution twice ok' do
          put api_product_institution_path(product, institution), headers: headers
          put api_product_institution_path(product, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.lessees).to include(institution.lessee)
          expect(product.lessees.count).to eq(1)
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end
      end
    end

    describe "DELETE /api/v1/institution/:id" do # destroy
      let(:product) { create(:product) }

      it 'non existing not_found' do
        delete api_institution_path(institution.id + 1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution")
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end

      it 'existing without products ok' do
        delete api_institution_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
        expect(Institution.count).to eq(0)
        expect(Lessee.count).to eq(0)
      end

      it 'existing with products accepted' do
        product.lessees << institution.lessee
        product.save
        delete api_institution_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:accepted)
        expect(response_body[:base.to_s]).to include("institution has 1 associated products!")
        expect(Institution.count).to eq(1)
        expect(Lessee.count).to eq(1)
      end
    end

    describe "DELETE /api/v1/products/:product_id:/institutions/:id" do # delete
      context 'non existing product' do
        it 'non existing institution not_found' do
          delete api_product_institution_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution with")
          expect(Institution.count).to eq(0)
          expect(Lessee.count).to eq(0)
        end

        it 'existing institution not_found' do
          delete api_product_institution_path(1, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Product with")
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        before do
          product.lessees << institution.lessee
          product.save
        end

        it 'non existing institution not_found' do
          delete api_product_institution_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution with")
          expect(product.lessees).to include(institution.lessee)
          expect(product.lessees.count).to eq(1)
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end

        it 'existing institution ok' do
          delete api_product_institution_path(product, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.lessees).to include(institution.lessee)
          expect(product.lessees.count).to eq(0)
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end

        it 'existing institution twice ok' do
          delete api_product_institution_path(product, institution), headers: headers
          delete api_product_institution_path(product, institution), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.lessees).to include(institution.lessee)
          expect(product.lessees.count).to eq(0)
          expect(Institution.count).to eq(1)
          expect(Lessee.count).to eq(1)
        end
      end
    end
  end
end
