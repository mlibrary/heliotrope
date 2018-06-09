# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Products", type: :request do
  def product_obj(product:)
    {
      "id" => product.id,
      "identifier" => product.identifier,
      "name" => product.name,
      "url" => product_url(product, format: :json)
    }
  end

  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:new_product) { build(:product, id: product.id + 1, identifier: new_identifier) }
  let(:new_identifier) { 'new_product' }
  let(:product) { create(:product, identifier: identifier) }
  let(:identifier) { 'product' }
  let(:response_body) { JSON.parse(@response.body) }

  before { product }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { product: { identifier: new_identifier, name: 'name', purchase: 'purchase' } } }

    it { get api_find_product_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_products_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_products_path, params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_path(product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_path(product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_find_product_path' do
      let(:params) { { identifier: new_identifier } }
      describe 'GET /api/v1/product' do
        it 'not found' do
          get api_find_product_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'found' do
          new_product.save
          get api_find_product_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).not_to be_empty
          expect(response_body).to eq(product_obj(product: new_product))
        end
      end
    end

    context 'api_v1_products_path' do
      describe "GET /api/v1/products" do # index
        it 'empty' do
          product.destroy!
          get api_products_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'product' do
          get api_products_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product)])
        end

        it 'products' do
          new_product.save!
          get api_products_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product), product_obj(product: new_product)])
        end
      end

      describe "POST /api/v1/products" do # create
        let(:input) { params.to_json }

        context 'blank identifier' do
          let(:params) { { product: { identifier: '', name: 'name', purchase: 'purchase' } } }

          it 'errors' do
            post api_products_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            expect(Product.all.count).to eq(1)
          end
        end

        context 'unique identifier' do
          let(:params) { { product: { identifier: new_identifier, name: 'name', purchase: 'purchase' } } }

          it 'creates product' do
            post api_products_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(new_identifier)
            expect(Product.find_by(identifier: new_identifier)).not_to be_nil
            expect(Product.all.count).to eq(2)
          end
        end

        context 'existing identifier' do
          let(:params) { { product: { identifier: identifier, name: 'name', purchase: 'purchase' } } }

          it 'does nothing' do
            post api_products_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Product.find_by(identifier: identifier)).not_to be_nil
            expect(Product.all.count).to eq(1)
          end
        end
      end
    end

    context 'api_v1_product_path' do
      describe "GET /api/v1/products/:id" do # show
        it 'does nothing' do
          get api_product_path(new_product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'returns product' do
          get api_product_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(product_obj(product: product))
        end
      end

      describe "DELETE /api/v1/products/:id" do # destroy
        it 'does nothing' do
          delete api_product_path(new_product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Product.find_by(identifier: new_identifier)).to be_nil
          expect(Product.all.count).to eq(1)
        end

        it 'deletes product' do
          delete api_product_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Product.find_by(identifier: identifier)).to be_nil
          expect(Product.all.count).to eq(0)
        end

        context 'product of lessee' do
          let(:lessee) { create(:lessee) }

          it 'does nothing' do
            product.lessees << lessee
            product.save!
            delete api_product_path(product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:accepted)
            expect(response.body).to be_empty
            expect(Product.find_by(identifier: identifier)).not_to be_nil
            expect(Product.all.count).to eq(1)
          end
        end
      end
    end
  end
end
