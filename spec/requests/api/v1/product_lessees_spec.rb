# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Product Lessees", type: :request do
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
  let(:product) { create(:product, identifier: product_identifier) }
  let(:product_identifier) { 'product' }
  let(:product2) { build(:product, id: product.id + 1, identifier: product2_identifier) }
  let(:product2_identifier) { 'product2' }
  let(:lessee) { create(:lessee, identifier: identifier) }
  let(:identifier) { 'lessee' }
  let(:lessee2) { build(:lessee, id: lessee.id + 1, identifier: identifier2) }
  let(:identifier2) { 'lessee2' }
  let(:response_body) { JSON.parse(@response.body) }
  let(:response_hash) { HashWithIndifferentAccess.new response_body }

  before do
    product
    lessee
  end

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { lessee: { identifier: identifier } } }

    it { get api_product_lessees_path(product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_product_lessees_path(product), params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_lessee_path(product, lessee), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { patch api_product_lessee_path(product, lessee), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_product_lessee_path(product, lessee), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_lessee_path(product, lessee), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_product_lessees_path' do
      describe "GET /api/v1/products/:product_id/lessees" do # index
        it 'product2 not found' do
          get api_product_lessees_path(product2), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).not_to be_empty
          expect(response_hash[:exception]).not_to be_empty
          expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
          expect(Product.all.count).to eq(1)
          expect(Lessee.all.count).to eq(1)
        end

        it 'product without lessee' do
          get api_product_lessees_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
          expect(Product.all.count).to eq(1)
          expect(Lessee.all.count).to eq(1)
        end

        it 'product with lessee' do
          product.lessees << lessee
          product.save!
          get api_product_lessees_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([lessee_obj(lessee: lessee)])
          expect(Product.all.count).to eq(1)
          expect(Lessee.all.count).to eq(1)
        end

        it 'product with lessees' do
          product.lessees << lessee
          product.lessees << lessee2
          product.save!
          get api_product_lessees_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([lessee_obj(lessee: lessee), lessee_obj(lessee: lessee2)])
          expect(Product.all.count).to eq(1)
          expect(Lessee.all.count).to eq(2)
        end
      end

      describe "POST /api/v1/products/:product_id/lessees" do # create
        let(:input) { params.to_json }
        let(:params) { { lessee: { identifier: identifier2 } } }

        context 'blank identifier' do
          let(:params) { { lessee: { identifier: '' } } }

          it 'product2 not found' do
            post api_product_lessees_path(product2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            product2 = Product.find_by(identifier: product2_identifier)
            lessee2 = Lessee.find_by(identifier: identifier2)
            expect(product2).to be_nil
            expect(lessee2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product without lessee' do
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            lessee2 = Lessee.find_by(identifier: identifier2)
            expect(product.lessees.count).to eq(0)
            expect(lessee2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product with lessee' do
            product.lessees << lessee
            product.save!
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            lessee2 = Lessee.find_by(identifier: identifier2)
            expect(product.lessees.count).to eq(1)
            expect(product.lessees).not_to include(lessee2)
            expect(lessee2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end
        end

        context 'lessee2 not found' do
          it 'product2 not found' do
            post api_product_lessees_path(product2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            product2 = Product.find_by(identifier: product2_identifier)
            lessee2 = Lessee.find_by(identifier: identifier2)
            expect(product2).to be_nil
            expect(lessee2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product without lessee' do
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            lessee2 = Lessee.find_by(identifier: identifier2)
            expect(product.lessees.count).to eq(1)
            expect(product.lessees.first).to eq(lessee2)
            expect(lessee2.products.count).to eq(1)
            expect(lessee2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end

          it 'product with lessee' do
            product.lessees << lessee
            product.save!
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            lessee2 = Lessee.find_by(identifier: identifier2)
            expect(product.lessees.count).to eq(2)
            expect(product.lessees).to include(lessee2)
            expect(lessee2.products.count).to eq(1)
            expect(lessee2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end
        end

        context 'lessee2' do
          before { lessee2.save! }

          it 'product2 not found' do
            post api_product_lessees_path(product2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            product2 = Product.find_by(identifier: product2_identifier)
            expect(product2).to be_nil
            expect(lessee2.products.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end

          it 'product without lessee' do
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(product.lessees.count).to eq(1)
            expect(product.lessees.first).to eq(lessee2)
            expect(lessee2.products.count).to eq(1)
            expect(lessee2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end

          it 'product with lessee' do
            product.lessees << lessee
            product.save!
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(product.lessees.count).to eq(2)
            expect(product.lessees).to include(lessee2)
            expect(lessee2.products.count).to eq(1)
            expect(lessee2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end

          it 'product with lessees' do
            product.lessees << lessee
            product.lessees << lessee2
            product.save!
            post api_product_lessees_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(product.lessees.count).to eq(2)
            expect(product.lessees).to include(lessee2)
            expect(lessee2.products.count).to eq(1)
            expect(lessee2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_product_lessees_path'

    context 'api_v1_product_lessee_path' do
      describe "GET /api/v1/products/:product_id/lessees/:id" do # show
        context 'product2 not found' do
          it 'lessee2 not found' do
            get api_product_lessee_path(product2, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'lessee' do
            get api_product_lessee_path(product2, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end
        end

        context 'product' do
          it 'lessee2 not found' do
            get api_product_lessee_path(product, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product without lessee' do
            get api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product with lessee' do
            product.lessees << lessee
            product.save!
            get api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product with lessees' do
            product.lessees << lessee
            product.lessees << lessee2
            product.save!
            get api_product_lessee_path(product, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end
        end
      end

      %w[patch put].each do |verb|
        describe "#{verb.upcase} /api/v1/products/:product_id/lessees/:id" do # update
          context 'product2 not found' do
            it 'lessee2 not found' do
              send(verb, api_product_lessee_path(product2, lessee2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: product2_identifier)
              lessee2 = Lessee.find_by(identifier: identifier2)
              expect(product2).to be_nil
              expect(lessee2).to be_nil
              expect(Product.all.count).to eq(1)
              expect(Lessee.all.count).to eq(1)
            end

            it 'lessee without product' do
              send(verb, api_product_lessee_path(product2, lessee), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: product2_identifier)
              expect(product2).to be_nil
              expect(lessee.products.count).to eq(0)
              expect(Product.all.count).to eq(1)
              expect(Lessee.all.count).to eq(1)
            end

            it 'lessee with product' do
              lessee.products << product
              lessee.save!
              send(verb, api_product_lessee_path(product2, lessee), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: product2_identifier)
              expect(product2).to be_nil
              expect(lessee.products.count).to eq(1)
              expect(lessee.products.first).to eq(product)
              expect(Product.all.count).to eq(1)
              expect(Lessee.all.count).to eq(1)
            end
          end

          context 'product2' do
            before { product2.save! }

            it 'lessee2 not found' do
              send(verb, api_product_lessee_path(product2, lessee2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Lessee")
              lessee2 = Lessee.find_by(identifier: identifier2)
              expect(product2.lessees.count).to eq(0)
              expect(lessee2).to be_nil
              expect(Product.all.count).to eq(2)
              expect(Lessee.all.count).to eq(1)
            end

            it 'lessee without product' do
              send(verb, api_product_lessee_path(product2, lessee), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              expect(product2.lessees.count).to eq(1)
              expect(product2.lessees.first).to eq(lessee)
              expect(lessee.products.count).to eq(1)
              expect(lessee.products.first).to eq(product2)
              expect(Product.all.count).to eq(2)
              expect(Lessee.all.count).to eq(1)
            end

            it 'lessee with product' do
              lessee.products << product
              lessee.save!
              send(verb, api_product_lessee_path(product2, lessee), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              expect(product2.lessees.count).to eq(1)
              expect(product2.lessees.first).to eq(lessee)
              expect(lessee.products.count).to eq(2)
              expect(lessee.products.first).to eq(product)
              expect(lessee.products.last).to eq(product2)
              expect(Product.all.count).to eq(2)
              expect(Lessee.all.count).to eq(1)
            end

            it 'lessee with products' do
              lessee.products << product
              lessee.products << product2
              lessee.save!
              send(verb, api_product_lessee_path(product2, lessee), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              product2 = Product.find_by(identifier: product2_identifier)
              expect(product2.lessees.count).to eq(1)
              expect(product2.lessees.first).to eq(lessee)
              expect(lessee.products.count).to eq(2)
              expect(lessee.products.first).to eq(product)
              expect(lessee.products.last).to eq(product2)
              expect(Product.all.count).to eq(2)
              expect(Lessee.all.count).to eq(1)
            end

            context 'lessee2' do
              before { lessee2.save! }

              it 'lessees with product' do
                lessee.products << product
                lessee.save!
                lessee2.products << product
                lessee2.save!
                send(verb, api_product_lessee_path(product2, lessee2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(identifier2)
                expect(product2.lessees.count).to eq(1)
                expect(product2.lessees.first).to eq(lessee2)
                expect(lessee2.products.count).to eq(2)
                expect(lessee2.products.first).to eq(product)
                expect(lessee2.products.last).to eq(product2)
                expect(Product.all.count).to eq(2)
                expect(Lessee.all.count).to eq(2)
              end

              it 'lessees with products' do
                lessee.products << product
                lessee.products << product2
                lessee.save!
                lessee2.products << product
                lessee2.products << product2
                lessee2.save!
                send(verb, api_product_lessee_path(product2, lessee2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(identifier2)
                expect(product2.lessees.count).to eq(2)
                expect(product2.lessees.first).to eq(lessee)
                expect(product2.lessees.last).to eq(lessee2)
                expect(lessee2.products.count).to eq(2)
                expect(lessee2.products.first).to eq(product)
                expect(lessee2.products.last).to eq(product2)
                expect(Product.all.count).to eq(2)
                expect(Lessee.all.count).to eq(2)
              end
            end
          end
        end
      end

      describe "DELETE /api/v1/products/:product_id/lessees/:id" do # destroy
        context 'product2 not found' do
          it 'lessee2 not found' do
            delete api_product_lessee_path(product2, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'lessee' do
            delete api_product_lessee_path(product2, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end
        end

        context 'product' do
          it 'lessee2 not found' do
            delete api_product_lessee_path(product, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product without lessee' do
            delete api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product with lessee' do
            product.lessees << lessee
            product.save!
            delete api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
            delete api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(1)
          end

          it 'product with lessees' do
            product.lessees << lessee
            product.lessees << lessee2
            product.save!
            delete api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(1)
            expect(product.lessees.first).to eq(lessee2)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
            delete api_product_lessee_path(product, lessee), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(1)
            expect(product.lessees.first).to eq(lessee2)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
            delete api_product_lessee_path(product, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
            delete api_product_lessee_path(product, lessee2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.lessees.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Lessee.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_product_lessee_path' do
  end
end
