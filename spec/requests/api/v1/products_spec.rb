# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Products", type: :request do
  def product_obj(product:)
    {
      "id" => product.id,
      "identifier" => product.identifier,
      "name" => product.name,
      "purchase" => product.purchase,
      "url" => product_url(product, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:product) { create(:product) }
  let(:response_body) { JSON.parse(@response.body) }

  before { clear_grants_table }

  context 'unauthorized' do
    it { get api_find_product_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_products_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_component_products_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individual_products_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_products_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_products_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_product_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe 'GET /api/v1/product' do # find
      it 'non existing not found' do
        get api_find_product_path, params: { identifier: 'identifier' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Product.count).to eq(0)
      end

      it 'existing ok' do
        get api_find_product_path, params: { identifier: product.identifier }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(product_obj(product: product))
        expect(Product.count).to eq(1)
      end
    end

    describe "GET /api/v1/products" do # index
      it 'empty ok' do
        get api_products_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Product.count).to eq(0)
      end

      it 'product ok' do
        product
        get api_products_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product)])
        expect(Product.count).to eq(1)
      end

      it 'products ok' do
        product
        new_product = create(:product)
        get api_products_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product), product_obj(product: new_product)])
        expect(Product.count).to eq(2)
      end
    end

    describe "GET /api/v1/component/:component_id/products" do # index
      let(:component) { create(:component) }
      let(:new_product) { create(:product) }

      before do
        product
        new_product
      end

      it 'not_found' do
        get api_component_products_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
        expect(Product.count).to eq(2)
      end

      it 'empty ok' do
        get api_component_products_path(component), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Product.count).to eq(2)
      end

      it 'product ok' do
        product.components << component
        get api_component_products_path(component), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product)])
        expect(Product.count).to eq(2)
      end

      it 'products ok' do
        product.components << component
        new_product.components << component
        get api_component_products_path(component), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product), product_obj(product: new_product)])
        expect(Product.count).to eq(2)
      end
    end

    describe "GET /api/v1/individual/:individual_id/products" do # index
      let(:individual) { create(:individual) }
      let(:new_product) { create(:product) }

      before do
        product
        new_product
      end

      it 'not_found' do
        get api_individual_products_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Individual")
        expect(Product.count).to eq(2)
      end

      it 'empty ok' do
        get api_individual_products_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Product.count).to eq(2)
      end

      it 'product ok' do
        Greensub.subscribe(subscriber: individual, target: product)
        get api_individual_products_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product)])
        expect(Product.count).to eq(2)
      end

      it 'products ok' do
        Greensub.subscribe(subscriber: individual, target: product)
        Greensub.subscribe(subscriber: individual, target: new_product)
        get api_individual_products_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product), product_obj(product: new_product)])
        expect(Product.count).to eq(2)
      end
    end

    describe "GET /api/v1/institution/:institution_id/products" do # index
      let(:institution) { create(:institution) }
      let(:new_product) { create(:product) }

      before do
        product
        new_product
      end

      it 'not_found' do
        get api_institution_products_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Institution")
        expect(Product.count).to eq(2)
      end

      it 'empty ok' do
        get api_institution_products_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Product.count).to eq(2)
      end

      it 'product ok' do
        Greensub.subscribe(subscriber: institution, target: product)
        get api_institution_products_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product)])
        expect(Product.count).to eq(2)
      end

      it 'products ok' do
        Greensub.subscribe(subscriber: institution, target: product)
        Greensub.subscribe(subscriber: institution, target: new_product)
        get api_institution_products_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([product_obj(product: product), product_obj(product: new_product)])
        expect(Product.count).to eq(2)
      end
    end

    describe "POST /api/v1/products" do # create
      let(:params) { { product: { identifier: identifier, name: name, purchase: purchase } }.to_json }

      context 'blank' do
        let(:identifier) { '' }
        let(:name) { '' }
        let(:purchase) { '' }

        it 'unprocessable_entity' do
          post api_products_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
          expect(response_body[:name.to_s]).to eq(["can't be blank"])
          expect(response_body[:purchase.to_s]).to be nil
          expect(Product.all.count).to eq(0)
        end
      end

      context 'non existing' do
        let(:identifier) { 'identifier' }
        let(:name) { 'name' }
        let(:purchase) { 'purchase' }

        it 'created' do
          post api_products_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:identifier.to_s]).to eq(identifier)
          expect(response_body[:name.to_s]).to eq(name)
          expect(response_body[:purchase.to_s]).to eq(purchase)
          expect(Product.count).to eq(1)
        end
      end

      context 'existing' do
        let(:identifier) { product.identifier }
        let(:name) { 'name' }
        let(:purchase) { 'purchase' }

        it 'unprocessable_entity' do
          post api_products_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["product identifier #{identifier} exists!"])
          expect(Product.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/products/:id" do # show
      it 'non existing not_found' do
        get api_product_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
        expect(Product.count).to eq(0)
      end

      it 'existing ok' do
        get api_product_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(product_obj(product: product))
        expect(Product.count).to eq(1)
      end
    end

    describe "PUT /api/v1/products/:id" do # update
      it 'non existing not_found' do
        put api_product_path(1), params: { product: { name: 'updated_name' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
        expect(Product.count).to eq(0)
      end

      it 'existing ok' do
        put api_product_path(product), params: { product: { name: 'updated_name' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body[:id.to_s]).to eq(product.id)
        expect(response_body[:name.to_s]).to eq('updated_name')
        expect(Product.count).to eq(1)
      end

      it 'existing update identifier unprocessable_entity' do
        put api_product_path(product), params: { product: { identifier: '' } }.to_json, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
        expect(Product.count).to eq(1)
      end
    end

    describe "DELETE /api/v1/products/:id" do # destroy
      let(:component) { create(:component) }

      it 'non existing not_found' do
        delete api_product_path(product.id + 1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
        expect(Product.count).to eq(1)
      end

      it 'existing without components ok' do
        delete api_product_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
        expect(Product.count).to eq(0)
      end

      it 'existing with components accepted' do
        product.components << component
        product.save
        delete api_product_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:accepted)
        expect(response_body[:base.to_s]).to include("product has 1 associated components!")
        expect(Product.count).to eq(1)
      end
    end
  end
end
