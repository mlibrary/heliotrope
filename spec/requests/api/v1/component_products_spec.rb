# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Component Products", type: :request do
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
  let(:component) { create(:component, handle: component_handle) }
  let(:component_handle) { 'component' }
  let(:component2) { build(:component, id: component.id + 1, handle: component2_handle) }
  let(:component2_handle) { 'component2' }
  let(:product) { create(:product, identifier: identifier, name: 'name') }
  let(:identifier) { 'product' }
  let(:product2) { build(:product, id: product.id + 1, identifier: identifier2, name: 'name') }
  let(:identifier2) { 'product2' }
  let(:response_body) { JSON.parse(@response.body) }
  let(:response_hash) { HashWithIndifferentAccess.new response_body }

  before do
    component
    product
  end

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { product: { identifier: identifier, name: 'name', purchase: 'purchase' } } }

    it { get api_component_products_path(component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_component_products_path(component), params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_component_product_path(component, product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { patch api_component_product_path(component, product), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_component_product_path(component, product), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_component_product_path(component, product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_component_products_path' do
      describe "GET /api/v1/components/:component_id/products" do # index
        it 'component2 not found' do
          get api_component_products_path(component2), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).not_to be_empty
          expect(response_hash[:exception]).not_to be_empty
          expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
          expect(Component.all.count).to eq(1)
          expect(Product.all.count).to eq(1)
        end

        it 'component without product' do
          get api_component_products_path(component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
          expect(Component.all.count).to eq(1)
          expect(Product.all.count).to eq(1)
        end

        it 'component with product' do
          component.products << product
          component.save!
          get api_component_products_path(component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product)])
          expect(Component.all.count).to eq(1)
          expect(Product.all.count).to eq(1)
        end

        it 'component with products' do
          component.products << product
          component.products << product2
          component.save!
          get api_component_products_path(component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([product_obj(product: product), product_obj(product: product2)])
          expect(Component.all.count).to eq(1)
          expect(Product.all.count).to eq(2)
        end
      end

      describe "POST /api/v1/components/:component_id/products" do # create
        let(:input) { params.to_json }
        let(:params) { { product: { identifier: identifier2, name: 'name', purchase: 'purchase' } } }

        context 'blank identifier' do
          let(:params) { { product: { identifier: '', name: 'name', purchase: 'purchase' } } }

          it 'component2 not found' do
            post api_component_products_path(component2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
            component2 = Component.find_by(identifier: component2_handle)
            product2 = Product.find_by(identifier: identifier2)
            expect(component2).to be_nil
            expect(product2).to be_nil
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component without product' do
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            product2 = Product.find_by(identifier: identifier2)
            expect(component.products.count).to eq(0)
            expect(product2).to be_nil
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component with product' do
            component.products << product
            component.save!
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            product2 = Product.find_by(identifier: identifier2)
            expect(component.products.count).to eq(1)
            expect(component.products).not_to include(product2)
            expect(product2).to be_nil
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end
        end

        context 'product2 not found' do
          it 'component2 not found' do
            post api_component_products_path(component2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
            component2 = Component.find_by(identifier: component2_handle)
            product2 = Product.find_by(identifier: identifier2)
            expect(component2).to be_nil
            expect(product2).to be_nil
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component without product' do
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            product2 = Product.find_by(identifier: identifier2)
            expect(component.products.count).to eq(1)
            expect(component.products.first).to eq(product2)
            expect(product2.components.count).to eq(1)
            expect(product2.components.first).to eq(component)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'component with product' do
            component.products << product
            component.save!
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            product2 = Product.find_by(identifier: identifier2)
            expect(component.products.count).to eq(2)
            expect(component.products).to include(product2)
            expect(product2.components.count).to eq(1)
            expect(product2.components.first).to eq(component)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end

        context 'product2' do
          before { product2.save! }

          it 'component2 not found' do
            post api_component_products_path(component2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
            component2 = Component.find_by(identifier: component2_handle)
            expect(component2).to be_nil
            expect(product2.components.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'component without product' do
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(component.products.count).to eq(1)
            expect(component.products.first).to eq(product2)
            expect(product2.components.count).to eq(1)
            expect(product2.components.first).to eq(component)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'component with product' do
            component.products << product
            component.save!
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(component.products.count).to eq(2)
            expect(component.products).to include(product2)
            expect(product2.components.count).to eq(1)
            expect(product2.components.first).to eq(component)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end

          it 'component with products' do
            component.products << product
            component.products << product2
            component.save!
            post api_component_products_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(component.products.count).to eq(2)
            expect(component.products).to include(product2)
            expect(product2.components.count).to eq(1)
            expect(product2.components.first).to eq(component)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_component_products_path'

    context 'api_v1_component_product_path' do
      describe "GET /api/v1/components/:component_id/products/:id" do # show
        context 'component2 not found' do
          it 'product2 not found' do
            get api_component_product_path(component2, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'product' do
            get api_component_product_path(component2, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end
        end

        context 'component' do
          it 'product2 not found' do
            get api_component_product_path(component, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component without product' do
            get api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component with product' do
            component.products << product
            component.save!
            get api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component with products' do
            component.products << product
            component.products << product2
            component.save!
            get api_component_product_path(component, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier2)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end
      end

      %w[patch put].each do |verb|
        describe "#{verb.upcase} /api/v1/components/:component_id/products/:id" do # update
          context 'component2 not found' do
            it 'product2 not found' do
              send(verb, api_component_product_path(component2, product2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
              component2 = Component.find_by(identifier: component2_handle)
              product2 = Product.find_by(identifier: identifier2)
              expect(component2).to be_nil
              expect(product2).to be_nil
              expect(Component.all.count).to eq(1)
              expect(Product.all.count).to eq(1)
            end

            it 'product without component' do
              send(verb, api_component_product_path(component2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
              component2 = Component.find_by(identifier: component2_handle)
              expect(component2).to be_nil
              expect(product.components.count).to eq(0)
              expect(Component.all.count).to eq(1)
              expect(Product.all.count).to eq(1)
            end

            it 'product with component' do
              product.components << component
              product.save!
              send(verb, api_component_product_path(component2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
              component2 = Component.find_by(identifier: component2_handle)
              expect(component2).to be_nil
              expect(product.components.count).to eq(1)
              expect(product.components.first).to eq(component)
              expect(Component.all.count).to eq(1)
              expect(Product.all.count).to eq(1)
            end
          end

          context 'component2' do
            before { component2.save! }

            it 'product2 not found' do
              send(verb, api_component_product_path(component2, product2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: identifier2)
              expect(component2.products.count).to eq(0)
              expect(product2).to be_nil
              expect(Component.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            it 'product without component' do
              send(verb, api_component_product_path(component2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              expect(component2.products.count).to eq(1)
              expect(component2.products.first).to eq(product)
              expect(product.components.count).to eq(1)
              expect(product.components.first).to eq(component2)
              expect(Component.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            it 'product with component' do
              product.components << component
              product.save!
              send(verb, api_component_product_path(component2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              expect(component2.products.count).to eq(1)
              expect(component2.products.first).to eq(product)
              expect(product.components.count).to eq(2)
              expect(product.components.first).to eq(component)
              expect(product.components.last).to eq(component2)
              expect(Component.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            it 'product with components' do
              product.components << component
              product.components << component2
              product.save!
              send(verb, api_component_product_path(component2, product), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(identifier)
              component2 = Component.find_by(handle: component2_handle)
              expect(component2.products.count).to eq(1)
              expect(component2.products.first).to eq(product)
              expect(product.components.count).to eq(2)
              expect(product.components.first).to eq(component)
              expect(product.components.last).to eq(component2)
              expect(Component.all.count).to eq(2)
              expect(Product.all.count).to eq(1)
            end

            context 'product2' do
              before { product2.save! }

              it 'products with component' do
                product.components << component
                product.save!
                product2.components << component
                product2.save!
                send(verb, api_component_product_path(component2, product2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(identifier2)
                expect(component2.products.count).to eq(1)
                expect(component2.products.first).to eq(product2)
                expect(product2.components.count).to eq(2)
                expect(product2.components.first).to eq(component)
                expect(product2.components.last).to eq(component2)
                expect(Component.all.count).to eq(2)
                expect(Product.all.count).to eq(2)
              end

              it 'products with products' do
                product.components << component
                product.components << component2
                product.save!
                product2.components << component
                product2.components << component2
                product2.save!
                send(verb, api_component_product_path(component2, product2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(identifier2)
                expect(component2.products.count).to eq(2)
                expect(component2.products.first).to eq(product)
                expect(component2.products.last).to eq(product2)
                expect(product2.components.count).to eq(2)
                expect(product2.components.first).to eq(component)
                expect(product2.components.last).to eq(component2)
                expect(Component.all.count).to eq(2)
                expect(Product.all.count).to eq(2)
              end
            end
          end
        end
      end

      describe "DELETE /api/v1/components/:component_id/product/:id" do # destroy
        context 'component2 not found' do
          it 'product2 not_found' do
            delete api_component_product_path(component2, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'product' do
            delete api_component_product_path(component2, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end
        end

        context 'component' do
          it 'product2 not found' do
            delete api_component_product_path(component, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component without product' do
            delete api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component with product' do
            component.products << product
            component.save!
            delete api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
            delete api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(1)
          end

          it 'component with products' do
            component.products << product
            component.products << product2
            component.save!
            delete api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(1)
            expect(component.products.first).to eq(product2)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
            delete api_component_product_path(component, product), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(1)
            expect(component.products.first).to eq(product2)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
            delete api_component_product_path(component, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
            delete api_component_product_path(component, product2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(component.products.count).to eq(0)
            expect(Component.all.count).to eq(1)
            expect(Product.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_component_products_path' do
  end
end
