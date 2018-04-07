# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Products", type: :request do
  def product_obj(product:)
    {
      "id" => product.id,
      "identifier" => product.identifier,
      "url" => product_url(product, format: :json)
    }
  end

  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:product) { create(:product, identifier: identifier) }
  let(:identifier) { 'product' }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { lessee: { identifier: identifier } } }

    it { get api_products_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_products_path, params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_path(identifier), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_path(identifier), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_vi_products_path' do
      describe "GET /api/v1/products" do # index
        it 'empty' do
          get api_products_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'product' do
          product
          get api_products_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product)])
        end

        it 'products' do
          product
          identifier2 = 'product2'
          product2 = create(:product, identifier: identifier2)
          get api_products_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product), product_obj(product: product2)])
        end
      end

      describe "POST /api/v1/products" do # create
        let(:input) { params.to_json }

        context 'blank identifier' do
          let(:params) { { product: { identifier: '' } } }

          it 'errors' do
            post api_products_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            expect(Product.all.count).to eq(0)
          end
        end

        context 'identifier' do
          let(:params) { { product: { identifier: identifier } } }

          it 'empty' do
            post api_products_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Product.find_by(identifier: identifier)).not_to be_nil
            expect(Product.all.count).to eq(1)
          end

          it 'exists' do
            product
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

    context 'api_product_path' do
      describe "GET /api/v1/products/:identifier" do # show
        it 'empty' do
          get api_product_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'product' do
          product
          get api_product_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(product_obj(product: product))
        end
      end

      describe "DELETE /api/v1/products/:identifier" do # destroy
        it 'empty' do
          delete api_product_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Product.find_by(identifier: identifier)).to be_nil
          expect(Product.all.count).to eq(0)
        end

        it 'product' do
          product
          delete api_product_path(identifier), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Product.find_by(identifier: identifier)).to be_nil
          expect(Product.all.count).to eq(0)
        end

        context 'lessee' do
          let(:lessee) { create(:lessee) }

          it 'product of lessee' do
            product
            product.lessees << lessee
            product.save!
            delete api_product_path(identifier), headers: headers
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
