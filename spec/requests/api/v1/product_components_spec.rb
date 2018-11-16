# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Product Components", type: :request do
  def component_obj(component:)
    {
      "id" => component.id,
      "identifier" => component.identifier,
      "name" => component.name,
      "noid" => component.noid,
      "handle" => component.handle,
      "url" => component_url(component, format: :json)
    }
  end

  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:product) { create(:product, identifier: product_identifier, name: 'name') }
  let(:product_identifier) { 'product' }
  let(:product2) { build(:product, id: product.id + 1, identifier: product2_identifier, name: 'name2') }
  let(:product2_identifier) { 'product2' }
  let(:component) { create(:component, identifier: component_identifier, name: 'name', noid: 'noid', handle: 'handle') }
  let(:component_identifier) { 'component' }
  let(:component2) { build(:component, id: component.id + 1, identifier: component2_identifier, name: 'name2', noid: 'noid2', handle: 'handle2') }
  let(:component2_identifier) { 'component2' }
  let(:response_body) { JSON.parse(@response.body) }
  let(:response_hash) { HashWithIndifferentAccess.new response_body }

  before do
    product
    component
  end

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { component: { identifier: component_identifier, name: 'name', noid: 'noid', handle: 'handle' } } }

    it { get api_product_components_path(product), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_product_components_path(product), params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_component_path(product, component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { patch api_product_component_path(product, component), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_product_component_path(product, component), headers: headers; headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_component_path(product, component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_product_components_path' do
      describe "GET /api/v1/products/:product_id/components" do # index
        it 'product2 not found' do
          get api_product_components_path(product2), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).not_to be_empty
          expect(response_hash[:exception]).not_to be_empty
          expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
          expect(Product.all.count).to eq(1)
          expect(Component.all.count).to eq(1)
        end

        it 'product without component' do
          get api_product_components_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
          expect(Product.all.count).to eq(1)
          expect(Component.all.count).to eq(1)
        end

        it 'product with component' do
          product.components << component
          product.save!
          get api_product_components_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([component_obj(component: component)])
          expect(Product.all.count).to eq(1)
          expect(Component.all.count).to eq(1)
        end

        it 'product with components' do
          product.components << component
          product.components << component2
          product.save!
          get api_product_components_path(product), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([component_obj(component: component), component_obj(component: component2)])
          expect(Product.all.count).to eq(1)
          expect(Component.all.count).to eq(2)
        end
      end

      describe "POST /api/v1/products/:product_id/components" do # create
        let(:input) { params.to_json }
        let(:params) { { component: { identifier: component2_identifier, name: 'name2', noid: 'noid2', handle: 'handle2' } } }

        context 'blank handle' do
          let(:params) { { component: { handle: '' } } }

          it 'product2 not found' do
            post api_product_components_path(product2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            product2 = Product.find_by(identifier: product2_identifier)
            component2 = Component.find_by(identifier: component2_identifier)
            expect(product2).to be_nil
            expect(component2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product without component' do
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            component2 = Component.find_by(identifier: component2_identifier)
            expect(product.components.count).to eq(0)
            expect(component2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product with component' do
            product.components << component
            product.save!
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            component2 = Component.find_by(identifier: component2_identifier)
            expect(product.components.count).to eq(1)
            expect(product.components).not_to include(component2)
            expect(component2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end
        end

        context 'component2 not found' do
          it 'product2 not found' do
            post api_product_components_path(product2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            product2 = Product.find_by(identifier: product2_identifier)
            component2 = Component.find_by(identifier: component2_identifier)
            expect(product2).to be_nil
            expect(component2).to be_nil
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product without component' do
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(component2_identifier)
            component2 = Component.find_by(identifier: component2_identifier)
            expect(product.components.count).to eq(1)
            expect(product.components.first).to eq(component2)
            expect(component2.products.count).to eq(1)
            expect(component2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end

          it 'product with component' do
            product.components << component
            product.save!
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(component2_identifier)
            component2 = Component.find_by(identifier: component2_identifier)
            expect(product.components.count).to eq(2)
            expect(product.components).to include(component2)
            expect(component2.products.count).to eq(1)
            expect(component2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end
        end

        context 'component2' do
          before { component2.save! }

          it 'product2 not found' do
            post api_product_components_path(product2), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            product2 = Product.find_by(identifier: product2_identifier)
            expect(product2).to be_nil
            expect(component2.products.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end

          it 'product without component' do
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(component2_identifier)
            expect(product.components.count).to eq(1)
            expect(product.components.first).to eq(component2)
            expect(component2.products.count).to eq(1)
            expect(component2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end

          it 'product with component' do
            product.components << component
            product.save!
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(component2_identifier)
            expect(product.components.count).to eq(2)
            expect(product.components).to include(component2)
            expect(component2.products.count).to eq(1)
            expect(component2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end

          it 'product with components' do
            product.components << component
            product.components << component2
            product.save!
            post api_product_components_path(product), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(component2_identifier)
            expect(product.components.count).to eq(2)
            expect(product.components).to include(component2)
            expect(component2.products.count).to eq(1)
            expect(component2.products.first).to eq(product)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_product_components_path'

    context 'api_v1_product_component_path' do
      describe "GET /api/v1/products/:product_id/components/:id" do # show
        context 'product2 not found' do
          it 'component2 not found' do
            get api_product_component_path(product2, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'component' do
            get api_product_component_path(product2, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end
        end

        context 'product' do
          it 'component2 not found' do
            get api_product_component_path(product, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product without component' do
            get api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).to be_empty
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product with component' do
            product.components << component
            product.save!
            get api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(component_identifier)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product with components' do
            product.components << component
            product.components << component2
            product.save!
            get api_product_component_path(product, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(component2_identifier)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end
        end
      end

      %w[patch put].each do |verb|
        describe "#{verb.upcase} /api/v1/products/:product_id/components/:id" do # update
          context 'product2 not found' do
            it 'component2 not found' do
              send(verb, api_product_component_path(product2, component2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: product2_identifier)
              component2 = Component.find_by(identifier: component2_identifier)
              expect(product2).to be_nil
              expect(component2).to be_nil
              expect(Product.all.count).to eq(1)
              expect(Component.all.count).to eq(1)
            end

            it 'component without product' do
              send(verb, api_product_component_path(product2, component), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: product2_identifier)
              expect(product2).to be_nil
              expect(component.products.count).to eq(0)
              expect(Product.all.count).to eq(1)
              expect(Component.all.count).to eq(1)
            end

            it 'component with product' do
              component.products << product
              component.save!
              send(verb, api_product_component_path(product2, component), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
              product2 = Product.find_by(identifier: product2_identifier)
              expect(product2).to be_nil
              expect(component.products.count).to eq(1)
              expect(component.products.first).to eq(product)
              expect(Product.all.count).to eq(1)
              expect(Component.all.count).to eq(1)
            end
          end

          context 'product2' do
            before { product2.save! }

            it 'component2 not found' do
              send(verb, api_product_component_path(product2, component2), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:not_found)
              expect(response.body).not_to be_empty
              expect(response_hash[:exception]).not_to be_empty
              expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Component")
              component2 = Component.find_by(identifier: component2_identifier)
              expect(product2.components.count).to eq(0)
              expect(component2).to be_nil
              expect(Product.all.count).to eq(2)
              expect(Component.all.count).to eq(1)
            end

            it 'component without product' do
              send(verb, api_product_component_path(product2, component), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(component_identifier)
              expect(product2.components.count).to eq(1)
              expect(product2.components.first).to eq(component)
              expect(component.products.count).to eq(1)
              expect(component.products.first).to eq(product2)
              expect(Product.all.count).to eq(2)
              expect(Component.all.count).to eq(1)
            end

            it 'component with product' do
              component.products << product
              component.save!
              send(verb, api_product_component_path(product2, component), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(component_identifier)
              expect(product2.components.count).to eq(1)
              expect(product2.components.first).to eq(component)
              expect(component.products.count).to eq(2)
              expect(component.products.first).to eq(product)
              expect(component.products.last).to eq(product2)
              expect(Product.all.count).to eq(2)
              expect(Component.all.count).to eq(1)
            end

            it 'component with products' do
              component.products << product
              component.products << product2
              component.save!
              send(verb, api_product_component_path(product2, component), headers: headers)
              expect(response.content_type).to eq("application/json")
              expect(response).to have_http_status(:ok)
              expect(response_body[:identifier.to_s]).to eq(component_identifier)
              product2 = Product.find_by(identifier: product2_identifier)
              expect(product2.components.count).to eq(1)
              expect(product2.components.first).to eq(component)
              expect(component.products.count).to eq(2)
              expect(component.products.first).to eq(product)
              expect(component.products.last).to eq(product2)
              expect(Product.all.count).to eq(2)
              expect(Component.all.count).to eq(1)
            end

            context 'component2' do
              before { component2.save! }

              it 'components with product' do
                component.products << product
                component.save!
                component2.products << product
                component2.save!
                send(verb, api_product_component_path(product2, component2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(component2_identifier)
                expect(product2.components.count).to eq(1)
                expect(product2.components.first).to eq(component2)
                expect(component2.products.count).to eq(2)
                expect(component2.products.first).to eq(product)
                expect(component2.products.last).to eq(product2)
                expect(Product.all.count).to eq(2)
                expect(Component.all.count).to eq(2)
              end

              it 'components with products' do
                component.products << product
                component.products << product2
                component.save!
                component2.products << product
                component2.products << product2
                component2.save!
                send(verb, api_product_component_path(product2, component2), headers: headers)
                expect(response.content_type).to eq("application/json")
                expect(response).to have_http_status(:ok)
                expect(response_body[:identifier.to_s]).to eq(component2_identifier)
                expect(product2.components.count).to eq(2)
                expect(product2.components.first).to eq(component)
                expect(product2.components.last).to eq(component2)
                expect(component2.products.count).to eq(2)
                expect(component2.products.first).to eq(product)
                expect(component2.products.last).to eq(product2)
                expect(Product.all.count).to eq(2)
                expect(Component.all.count).to eq(2)
              end
            end
          end
        end
      end

      describe "DELETE /api/v1/products/:product_id/components/:id" do # destroy
        context 'product2 not found' do
          it 'component2 not found' do
            delete api_product_component_path(product2, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'component' do
            delete api_product_component_path(product2, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:not_found)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("ActiveRecord::RecordNotFound: Couldn't find Product")
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end
        end

        context 'product' do
          it 'component2 not found' do
            delete api_product_component_path(product, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product without component' do
            delete api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product with component' do
            product.components << component
            product.save!
            delete api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
            delete api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(1)
          end

          it 'product with components' do
            product.components << component
            product.components << component2
            product.save!
            delete api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(1)
            expect(product.components.first).to eq(component2)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
            delete api_product_component_path(product, component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(1)
            expect(product.components.first).to eq(component2)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
            delete api_product_component_path(product, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
            delete api_product_component_path(product, component2), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_empty
            expect(product.components.count).to eq(0)
            expect(Product.all.count).to eq(1)
            expect(Component.all.count).to eq(2)
          end
        end
      end
    end # context 'api_v1_product_component_path' do
  end
end
