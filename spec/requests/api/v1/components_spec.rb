# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components", type: :request do
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
  let(:new_component) { build(:component, id: component.id + 1, identifier: new_identifier, name: 'new_name', noid: 'new_noid', handle: 'new_handle') }
  let(:new_identifier) { 'new_component' }
  let(:component) { create(:component, identifier: identifier, name: 'name', noid: 'noid', handle: 'handle') }
  let(:identifier) { 'component' }
  let(:response_body) { JSON.parse(@response.body) }

  before { component }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { component: { identifier: new_identifier, name: 'new_name', noid: 'new_noid', handle: 'new_handle' } } }

    it { get api_find_component_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_components_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_components_path, params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_component_path(component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_component_path(component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_find_component_path' do
      let(:params) { { identifier: new_identifier } }

      describe 'GET /api/v1/component' do
        it 'not found' do
          get api_find_component_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'found' do
          new_component.save
          get api_find_component_path, params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).not_to be_empty
          expect(response_body).to eq(component_obj(component: new_component))
        end
      end
    end

    context 'api_v1_lessess_path' do
      describe "GET /api/v1/components" do # index
        it 'empty' do
          component.destroy!
          get api_components_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([])
        end

        it 'component' do
          get api_components_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([component_obj(component: component)])
        end

        it 'components' do
          new_component.save!
          get api_components_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq([component_obj(component: component), component_obj(component: new_component)])
        end
      end

      describe "POST /api/v1/components" do # create
        let(:input) { params.to_json }

        context 'blank identifier' do
          let(:params) { { component: { identifier: '', name: 'new_name', noid: 'new_noid', handle: 'new_handle' } } }

          it 'errors' do
            post api_components_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            expect(Component.all.count).to eq(1)
          end
        end

        context 'unique identifier' do
          let(:params) { { component: { identifier: new_identifier, name: 'new_name', noid: 'new_noid', handle: 'new_handle' } } }

          it 'creates component' do
            post api_components_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:identifier.to_s]).to eq(new_identifier)
            expect(Component.find_by(identifier: new_identifier)).not_to be_nil
            expect(Component.all.count).to eq(2)
          end
        end

        context 'existing identifier' do
          let(:params) { { component: { identifier: identifier, name: 'new_name', noid: 'new_noid', handle: 'new_handle' } } }

          it 'does nothing' do
            post api_components_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Component.find_by(identifier: identifier)).not_to be_nil
            expect(Component.all.count).to eq(1)
          end
        end
      end
    end

    context 'api_v1_component_path' do
      describe "GET /api/v1/components/:id" do # show
        it 'does nothing' do
          get api_component_path(new_component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it 'returns component' do
          get api_component_path(component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(component_obj(component: component))
        end
      end

      describe "PUT /api/v1/components/:id" do # update
        let(:input) { params.to_json }

        context 'does nothing' do
          let(:params) { { component: { identifier: '', name: 'name', noid: 'noid', handle: 'handle' } } }

          it 'errors' do
            put api_component_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:identifier.to_s]).to eq(["can't be blank"])
            expect(Component.all.count).to eq(1)
          end
        end

        context 'unique identifier' do
          let(:params) { { component: { identifier: new_identifier, name: 'name', noid: 'noid', handle: 'handle' } } }

          it 'updates component' do
            put api_component_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(new_identifier)
            expect(Component.find_by(identifier: new_identifier)).not_to be_nil
            expect(Component.all.count).to eq(1)
          end
        end

        context 'existing identifier' do
          let(:params) { { component: { identifier: identifier, name: 'name', noid: 'noid', handle: 'handle' } } }

          it 'does nothing' do
            put api_component_path(component), params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:identifier.to_s]).to eq(identifier)
            expect(Component.find_by(identifier: identifier)).not_to be_nil
            expect(Component.all.count).to eq(1)
          end
        end
      end

      describe "DELETE /api/v1/components/:id" do # destroy
        it 'does nothing' do
          delete api_component_path(new_component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Component.find_by(identifier: new_identifier)).to be_nil
          expect(Component.all.count).to eq(1)
        end

        it 'deletes component' do
          delete api_component_path(component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Component.find_by(identifier: identifier)).to be_nil
          expect(Component.all.count).to eq(0)
        end

        context 'component of product' do
          let(:product) { create(:product) }

          it 'does nothing' do
            component.products << product
            component.save!
            delete api_component_path(component), headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:accepted)
            expect(response.body).to be_empty
            expect(Component.find_by(identifier: identifier)).not_to be_nil
            expect(Component.all.count).to eq(1)
          end
        end
      end
    end
  end
end
