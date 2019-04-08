# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components", type: :request do
  def component_obj(component:)
    {
      "id" => component.id,
      "identifier" => component.identifier,
      "name" => component.name,
      "noid" => component.noid,
      "url" => greensub_component_url(component, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:component) { create(:component) }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it { get api_find_component_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_components_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_component_products_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_components_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_component_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_component_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_component_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_product_component_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_component_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_product_component_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe 'GET /api/v1/component' do
      it 'non existing not_found' do
        get api_find_component_path, params: { identifier: 'identifier' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Greensub::Component.count).to eq(0)
      end

      it 'existing ok' do
        get api_find_component_path, params: { identifier: component.identifier }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(component_obj(component: component))
        expect(Greensub::Component.count).to eq(1)
      end
    end

    describe "GET /api/v1/components" do # index
      it 'empty ok' do
        get api_components_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::Component.count).to eq(0)
      end

      it 'component ok' do
        component
        get api_components_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([component_obj(component: component)])
        expect(Greensub::Component.count).to eq(1)
      end

      it 'components ok' do
        component
        new_component = create(:component)
        get api_components_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([component_obj(component: component), component_obj(component: new_component)])
        expect(Greensub::Component.count).to eq(2)
      end
    end

    describe "GET /api/v1/product/:product_id/components" do # index
      let(:product) { create(:product) }
      let(:new_component) { create(:component) }

      before do
        component
        new_component
      end

      it 'not_found' do
        get api_product_components_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product")
        expect(Greensub::Component.count).to eq(2)
      end

      it 'empty ok' do
        get api_product_components_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::Component.count).to eq(2)
      end

      it 'product ok' do
        product.components << component
        get api_product_components_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([component_obj(component: component)])
        expect(Greensub::Component.count).to eq(2)
      end

      it 'products ok' do
        product.components << component
        product.components << new_component
        get api_product_components_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([component_obj(component: component), component_obj(component: new_component)])
        expect(Greensub::Component.count).to eq(2)
      end
    end

    describe "POST /api/v1/components" do # create
      let(:params) { { component: { identifier: identifier, name: name, noid: noid } }.to_json }
      let(:identifier) { '' }
      let(:name) { '' }
      let(:noid) { 'noid' }
      let(:entity) { double('entity', valid?: valid) }
      let(:valid) { true }

      before { allow(Sighrax).to receive(:factory).with(noid).and_return(entity) }

      it 'blank identifier' do
        post api_components_path, params: params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
        expect(response_body[:name.to_s]).to be nil
        expect(response_body[:noid.to_s]).to be nil
        expect(Greensub::Component.count).to eq(0)
      end

      context 'identifier' do
        let(:identifier) { 'identifier' }

        it 'existing noid' do
          post api_components_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body[:identifier.to_s]).to eq(identifier)
          expect(response_body[:name.to_s]).to eq(name)
          expect(response_body[:noid.to_s]).to eq(noid)
          expect(Greensub::Component.count).to eq(1)
        end

        context 'non existing noid' do
          let(:valid) { false }

          it do
            post api_components_path, params: params, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to be nil
            expect(response_body[:name.to_s]).to be nil
            expect(response_body[:noid.to_s]).to eq(["component noid '#{noid}' does not exists!"])
            expect(Greensub::Component.count).to eq(0)
          end
        end
      end

      context 'existing identifier' do
        let(:identifier) { component.identifier }

        it do
          post api_components_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["component identifier #{identifier} exists!"])
          expect(Greensub::Component.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/component/:id" do # show
      it 'non existing not_found' do
        get api_component_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component")
        expect(Greensub::Component.count).to eq(0)
      end

      it 'existing ok' do
        get api_component_path(component), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(component_obj(component: component))
        expect(Greensub::Component.count).to eq(1)
      end
    end

    describe "GET /api/v1/products/:product_id:/components/:id" do # show
      context 'non existing product' do
        it 'non existing component not_found' do
          get api_product_component_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component with")
          expect(Greensub::Component.count).to eq(0)
        end

        it 'existing component not_found' do
          get api_product_component_path(1, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
          expect(Greensub::Component.count).to eq(1)
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing component not_found' do
          get api_product_component_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component with")
          expect(Greensub::Component.count).to eq(0)
        end

        it 'existing component ok' do
          put api_product_component_path(product, component), headers: headers
          get api_product_component_path(product, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(component_obj(component: component))
          expect(product.components).to include(component)
          expect(product.components.count).to eq(1)
          expect(Greensub::Component.count).to eq(1)
        end
      end
    end

    describe "PUT /api/v1/component" do # update
      let(:params) { { component: { identifier: identifier, name: name, noid: noid } }.to_json }
      let(:identifier) { 'updated_identifier' }
      let(:name) { 'updated_name' }
      let(:noid) { 'updated_noid' }
      let(:entity) { double('entity', valid?: valid) }
      let(:valid) { true }

      before { allow(Sighrax).to receive(:factory).with(noid).and_return(entity) }

      it 'non existing not_found' do
        put api_component_path(1), params: params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component")
        expect(Greensub::Component.count).to eq(0)
      end

      it 'existing ok' do
        put api_component_path(component.id), params: params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body[:id.to_s]).to eq(component.id)
        expect(response_body[:name.to_s]).to eq('updated_name')
        expect(Greensub::Component.count).to eq(1)
      end

      context 'existing update identifier unprocessable_entity' do
        let(:identifier) { '' }

        it do
          put api_component_path(component.id), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
          expect(Greensub::Component.count).to eq(1)
        end
      end

      context 'existing update noid unprocessable_entity' do
        let(:valid) { false }

        it do
          put api_component_path(component.id), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:noid.to_s]).to eq(["component noid '#{noid}' does not exists!"])
          expect(Greensub::Component.count).to eq(1)
        end
      end
    end

    describe "PUT /api/v1/products/:product_id:/components/:id" do # update
      context 'non existing product' do
        it 'non existing component not_found' do
          put api_product_component_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component with")
          expect(Greensub::Component.count).to eq(0)
        end

        it 'existing component not_found' do
          put api_product_component_path(1, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
          expect(Greensub::Component.count).to eq(1)
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        it 'non existing component not_found' do
          put api_product_component_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component with")
          expect(Greensub::Component.count).to eq(0)
        end

        it 'existing component ok' do
          put api_product_component_path(product, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.components).to include(component)
          expect(product.components.count).to eq(1)
          expect(Greensub::Component.count).to eq(1)
        end

        it 'existing component twice ok' do
          put api_product_component_path(product, component), headers: headers
          put api_product_component_path(product, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.components).to include(component)
          expect(product.components.count).to eq(1)
          expect(Greensub::Component.count).to eq(1)
        end
      end
    end

    describe "DELETE /api/v1/component/:id" do # destroy
      let(:product) { create(:product) }

      it 'non existing not_found' do
        delete api_component_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component")
        expect(Greensub::Component.count).to eq(0)
      end

      it 'existing without products ok' do
        delete api_component_path(component), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
        expect(Greensub::Component.count).to eq(0)
      end

      it 'existing with products accepted' do
        product.components << component
        product.save
        delete api_component_path(component), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:accepted)
        expect(response_body[:base.to_s]).to include("component has 1 associated products!")
        expect(Greensub::Component.count).to eq(1)
      end
    end

    describe "DELETE /api/v1/products/:product_id:/components/:id" do # delete
      context 'non existing product' do
        it 'non existing component not_found' do
          delete api_product_component_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component with")
          expect(Greensub::Component.count).to eq(0)
        end

        it 'existing component not_found' do
          delete api_product_component_path(1, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Product with")
          expect(Greensub::Component.count).to eq(1)
        end
      end

      context 'existing product' do
        let(:product) { create(:product) }

        before do
          product.components << component
          product.save
        end

        it 'non existing component not_found' do
          delete api_product_component_path(product, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Component with")
          expect(product.components).to include(component)
          expect(product.components.count).to eq(1)
          expect(Greensub::Component.count).to eq(1)
        end

        it 'existing component ok' do
          delete api_product_component_path(product, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.components).to include(component)
          expect(product.components.count).to eq(0)
          expect(Greensub::Component.count).to eq(1)
        end

        it 'existing component twice ok' do
          delete api_product_component_path(product, component), headers: headers
          delete api_product_component_path(product, component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(product.components).to include(component)
          expect(product.components.count).to eq(0)
          expect(Greensub::Component.count).to eq(1)
        end
      end
    end
  end
end
