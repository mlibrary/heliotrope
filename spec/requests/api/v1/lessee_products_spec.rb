# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessee Products", type: :request do
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
  let(:lessee) { create(:lessee, identifier: lessee_identifier) }
  let(:lessee_identifier) { 'lessee' }
  let(:lessee2) { build(:lessee, id: lessee.id + 1, identifier: lessee2_identifier) }
  let(:lessee2_identifier) { 'lessee2' }
  let(:product) { create(:product, identifier: identifier, name: 'name') }
  let(:identifier) { 'product' }
  let(:product2) { build(:product, id: product.id + 1, identifier: identifier2, name: 'name') }
  let(:identifier2) { 'product2' }
  let(:response_body) { JSON.parse(@response.body) }
  let(:response_hash) { HashWithIndifferentAccess.new response_body }

  before do
    lessee
    product
  end

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { product: { identifier: identifier, name: 'name', purchase: 'purchase' } } }

    it { get api_lessee_products_path(lessee), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_lessee_products_path(lessee), params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_lessee_product_path(lessee, product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { patch api_lessee_product_path(lessee, product), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_lessee_product_path(lessee, product), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_lessee_product_path(lessee, product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_lessee_products_path' do
      describe "GET /api/v1/lessees/:lessee_id/products" do # index
        it 'lessee2 not found' do
          get api_lessee_products_path(lessee2), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).not_to be_empty
          expect(response_hash[:exception]).not_to be_empty
          expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
          expect(Lessee.all.count).to eq(1)
          expect(Product.all.count).to eq(1)
        end

        it 'lessee without product' do
          get api_lessee_products_path(lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
          expect(Lessee.all.count).to eq(1)
          expect(Product.all.count).to eq(1)
        end

        it 'lessee with product' do
          lessee.products << product
          lessee.save!
          get api_lessee_products_path(lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product)])
          expect(Lessee.all.count).to eq(1)
          expect(Product.all.count).to eq(1)
        end

        it 'lessee with products' do
          lessee.products << product
          lessee.products << product2
          lessee.save!
          get api_lessee_products_path(lessee), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product), product_obj(product: product2)])
          expect(Lessee.all.count).to eq(1)
          expect(Product.all.count).to eq(2)
        end
      end

      describe "POST /api/v1/lessees/:lessee_id/products" do # create
        let(:input) { params.to_json }
        let(:params) { { product: { identifier: identifier2, name: 'name', purchase: 'purchase' } } }

        context 'blank identifier' do
          let(:params) { { product: { identifier: '', name: 'name', purchase: 'purchase' } } }

          it 'lessee2 not found' do
            post api_lessee_products_path(lessee2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
            lessee2 = Lessee.find_by(identifier: lessee2_identifier)
            product2 = Product.find_by(identifier: identifier2)
            expect(lessee2).to be_nil
            expect(product2).to be_nil
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee without product' do
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            product2 = Product.find_by(identifier: identifier2)
            expect(lessee.products.count).to eq(0)
            expect(product2).to be_nil
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee with product' do
            lessee.products << product
            lessee.save!
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            product2 = Product.find_by(identifier: identifier2)
            expect(lessee.products.count).to eq(1)
            expect(lessee.products).not_to include(product2)
            expect(product2).to be_nil
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end
        end

        context 'product2 not found' do
          it 'lessee2 not found' do
            post api_lessee_products_path(lessee2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
            lessee2 = Lessee.find_by(identifier: lessee2_identifier)
            product2 = Product.find_by(identifier: identifier2)
            expect(lessee2).to be_nil
            expect(product2).to be_nil
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee without product' do
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            product2 = Product.find_by(identifier: identifier2)
            expect(lessee.products.count).to eq(1)
            expect(lessee.products.first).to eq(product2)
            expect(product2.lessees.count).to eq(1)
            expect(product2.lessees.first).to eq(lessee)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'lessee with product' do
            lessee.products << product
            lessee.save!
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            product2 = Product.find_by(identifier: identifier2)
            expect(lessee.products.count).to eq(2)
            expect(lessee.products).to include(product2)
            expect(product2.lessees.count).to eq(1)
            expect(product2.lessees.first).to eq(lessee)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end

        context 'product2' do
          before { product2.save! }

          it 'lessee2 not found' do
            post api_lessee_products_path(lessee2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
            lessee2 = Lessee.find_by(identifier: lessee2_identifier)
            expect(lessee2).to be_nil
            expect(product2.lessees.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'lessee without product' do
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(lessee.products.count).to eq(1)
            expect(lessee.products.first).to eq(product2)
            expect(product2.lessees.count).to eq(1)
            expect(product2.lessees.first).to eq(lessee)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'lessee with product' do
            lessee.products << product
            lessee.save!
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(lessee.products.count).to eq(2)
            expect(lessee.products).to include(product2)
            expect(product2.lessees.count).to eq(1)
            expect(product2.lessees.first).to eq(lessee)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'lessee with products' do
            lessee.products << product
            lessee.products << product2
            lessee.save!
            post api_lessee_products_path(lessee), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(lessee.products.count).to eq(2)
            expect(lessee.products).to include(product2)
            expect(product2.lessees.count).to eq(1)
            expect(product2.lessees.first).to eq(lessee)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_lessee_products_path'

    context 'api_v1_lessee_product_path' do
      describe "GET /api/v1/lessees/:lessee_id/products/:id" do # show
        context 'lessee2 not found' do
          it 'product2 not found' do
            get api_lessee_product_path(lessee2, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'product' do
            get api_lessee_product_path(lessee2, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end
        end

        context 'lessee' do
          it 'product2 not found' do
            get api_lessee_product_path(lessee, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee without product' do
            get api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee with product' do
            lessee.products << product
            lessee.save!
            get api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee with products' do
            lessee.products << product
            lessee.products << product2
            lessee.save!
            get api_lessee_product_path(lessee, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end
      end

      %w[patch put].each do |verb|
        describe "#{verb.upcase} /api/v1/lessees/:lessee_id/products/:id" do # update
          context 'lessee2 not found' do
            it 'product2 not found' do
              send(verb, api_lessee_product_path(lessee2, product2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
              lessee2 = Lessee.find_by(identifier: lessee2_identifier)
              product2 = Product.find_by(identifier: identifier2)
              expect(lessee2).to be_nil
              expect(product2).to be_nil
              expect(Lessee.all.count).to eq(1)
              expect(Product.all.count).to eq(1)
            end

            it 'product without lessee' do
              send(verb, api_lessee_product_path(lessee2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
              lessee2 = Lessee.find_by(identifier: lessee2_identifier)
              expect(lessee2).to be_nil
              expect(product.lessees.count).to eq(0)
              expect(Lessee.all.count).to eq(1)
              expect(Product.all.count).to eq(1)
            end

            it 'product with lessee' do
              product.lessees << lessee
              product.save!
              send(verb, api_lessee_product_path(lessee2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
              lessee2 = Lessee.find_by(identifier: lessee2_identifier)
              expect(lessee2).to be_nil
              expect(product.lessees.count).to eq(1)
              expect(product.lessees.first).to eq(lessee)
              expect(Lessee.all.count).to eq(1)
              expect(Product.all.count).to eq(1)
            end
          end

          context 'lessee2' do
            before { lessee2.save! }

            it 'product2 not found' do
              send(verb, api_lessee_product_path(lessee2, product2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: identifier2)
              expect(lessee2.products.count).to eq(0)
              expect(product2).to be_nil
              expect(Lessee.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            it 'product without lessee' do
              send(verb, api_lessee_product_path(lessee2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              expect(lessee2.products.count).to eq(1)
              expect(lessee2.products.first).to eq(product)
              expect(product.lessees.count).to eq(1)
              expect(product.lessees.first).to eq(lessee2)
              expect(Lessee.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            it 'product with lessee' do
              product.lessees << lessee
              product.save!
              send(verb, api_lessee_product_path(lessee2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              expect(lessee2.products.count).to eq(1)
              expect(lessee2.products.first).to eq(product)
              expect(product.lessees.count).to eq(2)
              expect(product.lessees.first).to eq(lessee)
              expect(product.lessees.last).to eq(lessee2)
              expect(Lessee.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            it 'product with lessees' do
              product.lessees << lessee
              product.lessees << lessee2
              product.save!
              send(verb, api_lessee_product_path(lessee2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              lessee2 = Lessee.find_by(identifier: lessee2_identifier)
              expect(lessee2.products.count).to eq(1)
              expect(lessee2.products.first).to eq(product)
              expect(product.lessees.count).to eq(2)
              expect(product.lessees.first).to eq(lessee)
              expect(product.lessees.last).to eq(lessee2)
              expect(Lessee.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            context 'product2' do
              before { product2.save! }

              it 'products with lessee' do
                product.lessees << lessee
                product.save!
                product2.lessees << lessee
                product2.save!
                send(verb, api_lessee_product_path(lessee2, product2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(identifier2)
                expect(lessee2.products.count).to eq(1)
                expect(lessee2.products.first).to eq(product2)
                expect(product2.lessees.count).to eq(2)
                expect(product2.lessees.first).to eq(lessee)
                expect(product2.lessees.last).to eq(lessee2)
                expect(Lessee.all.count).to eq(2)
                expect(Product.all.count).to eq(2)
              end

              it 'products with products' do
                product.lessees << lessee
                product.lessees << lessee2
                product.save!
                product2.lessees << lessee
                product2.lessees << lessee2
                product2.save!
                send(verb, api_lessee_product_path(lessee2, product2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(identifier2)
                expect(lessee2.products.count).to eq(2)
                expect(lessee2.products.first).to eq(product)
                expect(lessee2.products.last).to eq(product2)
                expect(product2.lessees.count).to eq(2)
                expect(product2.lessees.first).to eq(lessee)
                expect(product2.lessees.last).to eq(lessee2)
                expect(Lessee.all.count).to eq(2)
                expect(Product.all.count).to eq(2)
              end
            end
          end
        end
      end

      describe "DELETE /api/v1/lessees/:lessee_id/product/:id" do # destroy
        context 'lessee2 not found' do
          it 'product2 not_found' do
            delete api_lessee_product_path(lessee2, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'product' do
            delete api_lessee_product_path(lessee2, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end
        end

        context 'lessee' do
          it 'product2 not found' do
            delete api_lessee_product_path(lessee, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee without product' do
            delete api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee with product' do
            lessee.products << product
            lessee.save!
            delete api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
            delete api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'lessee with products' do
            lessee.products << product
            lessee.products << product2
            lessee.save!
            delete api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(1)
            expect(lessee.products.first).to eq(product2)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
            delete api_lessee_product_path(lessee, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(1)
            expect(lessee.products.first).to eq(product2)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
            delete api_lessee_product_path(lessee, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
            delete api_lessee_product_path(lessee, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(lessee.products.count).to eq(0)
            expect(Lessee.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_lessee_products_path' do
  end
end
