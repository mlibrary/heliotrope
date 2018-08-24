# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components", type: :request do
  def component_obj(component:)
    {
      "id" => component.id,
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
  let(:new_component) { build(:component, id: component.id + 1, handle: new_handle) }
  let(:new_handle) { 'new_component' }
  let(:component) { create(:component, handle: handle) }
  let(:handle) { 'component' }
  let(:response_body) { JSON.parse(@response.body) }

  before { component }

  context 'unauthorized' do
    let(:input) { params.to_json }
    let(:params) { { component: { handle: new_handle } } }

    it { get api_find_component_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_components_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_components_path, params: input, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_component_path(component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_component_path(component), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    context 'api_v1_find_component_path' do
      let(:params) { { handle: new_handle } }

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

        context 'blank handle' do
          let(:params) { { component: { handle: '' } } }

          it 'errors' do
            post api_components_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:handle.to_s]).to eq(["can't be blank"])
            expect(Component.all.count).to eq(1)
          end
        end

        context 'unique handle' do
          let(:params) { { component: { handle: new_handle } } }

          it 'creates component' do
            post api_components_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:handle.to_s]).to eq(new_handle)
            expect(Component.find_by(handle: new_handle)).not_to be_nil
            expect(Component.all.count).to eq(2)
          end
        end

        context 'existing handle' do
          let(:params) { { component: { handle: handle } } }

          it 'does nothing' do
            post api_components_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:handle.to_s]).to eq(handle)
            expect(Component.find_by(handle: handle)).not_to be_nil
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

      describe "DELETE /api/v1/components/:id" do # destroy
        it 'does nothing' do
          delete api_component_path(new_component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Component.find_by(handle: new_handle)).to be_nil
          expect(Component.all.count).to eq(1)
        end

        it 'deletes component' do
          delete api_component_path(component), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Component.find_by(handle: handle)).to be_nil
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
            expect(Component.find_by(handle: handle)).not_to be_nil
            expect(Component.all.count).to eq(1)
          end
        end
      end
    end
  end
end
