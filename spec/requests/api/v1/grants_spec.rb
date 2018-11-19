# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Grants", type: :request do
  def grant_obj(grant:)
    {
      "id" => grant.id,
      "url" => grant_url(grant, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it { get api_grants_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_product_grants_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_individual_grants_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_grants_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_grants_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_grant_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_grant_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before do
      allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil)
      Checkpoint::DB.db[:permits].delete
    end

    describe "GET /api/v1/grant and GET /api/v1/grants" do # find and index
      let(:product) { create(:product) }
      let(:product_response_body) { JSON.parse(@response.body) }
      let(:individual) { create(:individual) }
      let(:individual_response_body) { JSON.parse(@response.body) }
      let(:institution) { create(:institution) }
      let(:institution_response_body) { JSON.parse(@response.body) }
      let(:individual_find_params) { { agent: "Individual:#{individual.id}", credential: credential, resource: resource } }
      let(:individual_find_response_body) { JSON.parse(@response.body) }
      let(:institution_find_params) { { agent: "Institution:#{institution.id}", credential: credential, resource: resource } }
      let(:institution_find_response_body) { JSON.parse(@response.body) }
      let(:credential) { 'permission:read' }
      let(:resource) { "Product:#{product.id}" }
      let(:individual_grant) { Grant.new(PermissionService.permit_read_access_resource(:Individual, individual.id, :Product, product.id)) }
      let(:institution_grant) { Grant.new(PermissionService.permit_read_access_resource(:Institution, institution.id, :Product, product.id)) }

      it 'empty' do
        get api_grants_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])

        get api_product_grants_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(product_response_body).to eq([])

        get api_individual_grants_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(individual_response_body).to eq([])

        get api_institution_grants_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(institution_response_body).to eq([])

        get api_find_grant_path, params: individual_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Grant.count).to eq(0)

        get api_find_grant_path, params: institution_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Grant.count).to eq(0)
      end

      it 'individual_grant' do
        individual_grant

        get api_grants_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([grant_obj(grant: individual_grant)])

        get api_product_grants_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(product_response_body).to eq([grant_obj(grant: individual_grant)])

        get api_individual_grants_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(individual_response_body).to eq([grant_obj(grant: individual_grant)])

        get api_institution_grants_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(institution_response_body).to eq([])

        get api_find_grant_path, params: individual_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(individual_find_response_body).to eq(grant_obj(grant: individual_grant))
        expect(Grant.count).to eq(1)

        get api_find_grant_path, params: institution_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Grant.count).to eq(1)
      end

      it 'institution_grant' do
        institution_grant

        get api_grants_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([grant_obj(grant: institution_grant)])

        get api_product_grants_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(product_response_body).to eq([grant_obj(grant: institution_grant)])

        get api_individual_grants_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(individual_response_body).to eq([])

        get api_institution_grants_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(institution_response_body).to eq([grant_obj(grant: institution_grant)])

        get api_find_grant_path, params: individual_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Grant.count).to eq(1)

        get api_find_grant_path, params: institution_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(institution_find_response_body).to eq(grant_obj(grant: institution_grant))
        expect(Grant.count).to eq(1)
      end

      it 'individual_grant and institutional_grant' do
        individual_grant
        institution_grant

        get api_grants_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([grant_obj(grant: individual_grant), grant_obj(grant: institution_grant)])

        get api_product_grants_path(product), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(product_response_body).to eq([grant_obj(grant: individual_grant), grant_obj(grant: institution_grant)])

        get api_individual_grants_path(individual), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(individual_response_body).to eq([grant_obj(grant: individual_grant)])

        get api_institution_grants_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(institution_response_body).to eq([grant_obj(grant: institution_grant)])

        get api_find_grant_path, params: individual_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(individual_find_response_body).to eq(grant_obj(grant: individual_grant))
        expect(Grant.count).to eq(2)

        get api_find_grant_path, params: institution_find_params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(institution_find_response_body).to eq(grant_obj(grant: institution_grant))
        expect(Grant.count).to eq(2)
      end
    end

    context 'grant' do
      let(:grant) { build(:grant) }

      before do
        allow(ValidationService).to receive(:valid_product?).with(anything).and_return(true)
        allow(ValidationService).to receive(:valid_individual?).with(anything).and_return(true)
        allow(ValidationService).to receive(:valid_institution?).with(anything).and_return(true)
        grant.save!
      end

      describe "POST /api/v1/grants" do # create
        let(:input) do
          { grant: {
            agent_type: :any, agent_id: :any, agent_token: 'any:any',
            credential_type: :permission, credential_id: :read, credential_token: 'permission:read',
            resource_type: :any, resource_id: :any, resource_token: 'any:any',
            zone_id: "(all)"
          } }.to_json
        end

        context 'invalid grant' do
          before { allow(ValidationService).to receive(:valid_agent?).with(anything, anything).and_return(false) }

          it 'errors' do
            post api_grants_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:agent_id.to_s]).to eq(["invalid value."])
            expect(Grant.count).to eq(1)
          end
        end

        context 'unique grant' do
          it 'creates grant' do
            post api_grants_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:id.to_s]).to eq(grant.id + 1)
            expect(Grant.find(grant.id + 1)).not_to be_nil
            expect(Grant.count).to eq(2)
          end
        end

        context 'existing grant' do
          it 'does nothing' do
            post api_grants_path, params: input, headers: headers
            post api_grants_path, params: input, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body[:id.to_s]).to eq(grant.id + 1)
            expect(Grant.find(grant.id + 1)).not_to be_nil
            expect(Grant.count).to eq(2)
          end
        end
      end

      describe "GET /api/v1/grants/:id" do # show
        it 'non existing not_found' do
          get api_grant_path(1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Grant")
          expect(Grant.count).to eq(1)
        end

        it 'existing ok' do
          get api_grant_path(grant), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(grant_obj(grant: grant))
          expect(Grant.count).to eq(1)
        end
      end

      describe "DELETE /api/v1/grants/:id" do # destroy
        it 'non existing not_found' do
          delete api_grant_path(1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Grant")
          expect(Grant.count).to eq(1)
        end

        it 'existing ok' do
          delete api_grant_path(grant), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(Grant.count).to eq(0)
        end
      end
    end
  end
end
