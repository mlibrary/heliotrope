# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "InstitutionAffiliations", type: :request do
  def institution_affiliation_obj(institution_affiliation:)
    {
      "id" => institution_affiliation.id,
      "institution_id" => institution_affiliation.institution_id,
      "dlps_institution_id" => institution_affiliation.dlps_institution_id,
      "affiliation" => institution_affiliation.affiliation,
      "url" => greensub_institution_affiliation_url(institution_affiliation, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:institution) { create(:institution) }
  let(:institution_affiliation) { create(:institution_affiliation) }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it { get api_institution_find_affiliation_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_affiliations_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { post api_institution_affiliations_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_institution_affiliation_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { put api_institution_affiliation_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { delete api_institution_affiliation_path(1, 1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe 'GET /api/v1/institution/:institution_id/affiliation' do
      it 'institution not_found' do
        get api_institution_find_affiliation_path(1), params: { dlps_institution_id: 1, affiliation: 'member' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution")
      end

      it 'non existing affiliation not_found' do
        get api_institution_find_affiliation_path(institution.id), params: { dlps_institution_id: 1, affiliation: 'member' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end

      it 'existing affiliation ok' do
        institution.affiliations << institution_affiliation
        get api_institution_find_affiliation_path(institution.id), params: { dlps_institution_id: institution_affiliation.dlps_institution_id, affiliation: institution_affiliation.affiliation }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(institution_affiliation_obj(institution_affiliation: institution_affiliation))
      end

      it 'existing affiliation but not this institution not_found' do
        get api_institution_find_affiliation_path(institution.id), params: { dlps_institution_id: institution_affiliation.dlps_institution_id, affiliation: institution_affiliation.affiliation }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end

    describe "GET /api/v1/institution/:institution_id/affiliations" do # index
      let(:new_institution_affiliation) { create(:institution_affiliation) }

      before do
        institution_affiliation
        new_institution_affiliation
      end

      it 'institution not_found' do
        get api_institution_affiliations_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution")
        expect(Greensub::InstitutionAffiliation.count).to eq(2)
      end

      it 'empty ok' do
        get api_institution_affiliations_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Greensub::InstitutionAffiliation.count).to eq(2)
      end

      it 'affiliation ok' do
        institution.affiliations << institution_affiliation
        get api_institution_affiliations_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([institution_affiliation_obj(institution_affiliation: institution_affiliation)])
        expect(Greensub::InstitutionAffiliation.count).to eq(2)
      end

      it 'affiliations ok' do
        institution.affiliations << institution_affiliation
        institution.affiliations << new_institution_affiliation
        get api_institution_affiliations_path(institution), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([institution_affiliation_obj(institution_affiliation: institution_affiliation), institution_affiliation_obj(institution_affiliation: new_institution_affiliation)])
        expect(Greensub::InstitutionAffiliation.count).to eq(2)
      end
    end

    describe "POST /api/v1/institution/:institution_id/affiliations" do # create
      let(:params) { { institution_affiliation: { dlps_institution_id: dlps_institution_id, affiliation: affiliation } }.to_json }
      let(:dlps_institution_id) { '' }
      let(:affiliation) { '' }

      it 'institution not_found' do
        post api_institution_affiliations_path(1), params: params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution")
        expect(Greensub::InstitutionAffiliation.count).to eq(0)
      end

      it 'invalid params' do
        post api_institution_affiliations_path(institution), params: params, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_body[:dlps_institution_id.to_s]).to eq(["can't be blank"])
        expect(response_body[:affiliation.to_s]).to eq(["can't be blank", "is not included in the list"])
        expect(Greensub::InstitutionAffiliation.count).to eq(0)
      end

      context 'valid params' do
        let(:dlps_institution_id) { '101' }
        let(:affiliation) { 'walk-in' }

        it 'creates affiliation' do
          post api_institution_affiliations_path(institution), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
          expect(response_body).to eq(institution_affiliation_obj(institution_affiliation: Greensub::InstitutionAffiliation.last))
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end
      end
    end

    describe "GET /api/v1/institutions/:institution_id:/affiliations/:id" do # show
      context 'non existing institution' do
        it 'non existing institution_affiliation not_found' do
          get api_institution_affiliation_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution with")
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end

        it 'existing institution_affiliation not_found' do
          get api_institution_affiliation_path(1, institution_affiliation), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution with")
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end
      end

      context 'existing institution' do
        it 'non existing institution_affiliation not_found' do
          get api_institution_affiliation_path(institution, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::InstitutionAffiliation with")
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end

        it 'existing institution_affiliation ok' do
          institution.affiliations << institution_affiliation
          get api_institution_affiliation_path(institution, institution_affiliation), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to eq(institution_affiliation_obj(institution_affiliation: institution_affiliation))
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end
      end
    end

    describe "PUT /api/v1/institutions/:institution_id:/affiliations/:id" do # update
      let(:params) { { institution_affiliation: { dlps_institution_id: dlps_institution_id, affiliation: affiliation } }.to_json }
      let(:dlps_institution_id) { 201 }
      let(:affiliation) { 'alum' }

      context 'non existing institution' do
        it 'non existing institution_affiliation not_found' do
          put api_institution_affiliation_path(1, 1), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution with")
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end

        it 'existing institution_affiliation not_found' do
          put api_institution_affiliation_path(1, institution_affiliation), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution with")
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end
      end

      context 'existing institution' do
        it 'non existing institution_affiliation not_found' do
          put api_institution_affiliation_path(institution, 1), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::InstitutionAffiliation with")
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end

        it 'existing institution_affiliation but not this institution unprocessable_entity' do
          put api_institution_affiliation_path(institution, institution_affiliation), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:institution_id.to_s]).to eq(["institution affiliation institution_id '#{institution_affiliation.institution_id}' does not match institution id '#{institution.id}'"])
          expect(institution.affiliations).not_to include(institution_affiliation)
          expect(institution.affiliations.count).to eq(0)
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end

        it 'existing institution_affiliation and this institution ok' do
          institution.affiliations << institution_affiliation
          put api_institution_affiliation_path(institution, institution_affiliation), params: params, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body[:id.to_s]).to eq(institution_affiliation.id)
          expect(response_body[:institution_id.to_s]).to eq(institution.id)
          expect(response_body[:dlps_institution_id.to_s]).to eq(dlps_institution_id)
          expect(response_body[:affiliation.to_s]).to eq(affiliation)
          expect(institution.affiliations).to include(institution_affiliation)
          expect(institution.affiliations.count).to eq(1)
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end
      end
    end

    describe "DELETE /api/v1/institutions/:institution_id:/affiliations/:id" do # delete
      context 'non existing institution' do
        it 'non existing institution_affiliation not_found' do
          delete api_institution_affiliation_path(1, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution with")
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end

        it 'existing institution_affiliation not_found' do
          delete api_institution_affiliation_path(1, institution_affiliation), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Greensub::Institution with")
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end
      end

      context 'existing institution' do
        it 'non existing institution_affiliation ok' do
          institution.affiliations << institution_affiliation
          delete api_institution_affiliation_path(institution, 1), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(institution.affiliations).to include(institution_affiliation)
          expect(institution.affiliations.count).to eq(1)
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end

        it 'existing institution_affiliation but not this institution unprocessable_entity' do
          delete api_institution_affiliation_path(institution, institution_affiliation), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response_body[:institution_id.to_s]).to eq(["institution affiliation institution_id '#{institution_affiliation.institution_id}' does not match institution id '#{institution.id}'"])
          expect(institution.affiliations).to be_empty
          expect(institution.affiliations.count).to eq(0)
          expect(Greensub::InstitutionAffiliation.count).to eq(1)
        end

        it 'existing institution_affiliation ok' do
          institution.affiliations << institution_affiliation
          delete api_institution_affiliation_path(institution, institution_affiliation), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(institution.affiliations).to include(institution_affiliation)
          expect(institution.affiliations.count).to eq(0)
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end

        it 'existing institution_affiliation twice ok' do
          institution.affiliations << institution_affiliation
          delete api_institution_affiliation_path(institution, institution_affiliation), headers: headers
          delete api_institution_affiliation_path(institution, institution_affiliation), headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_empty
          expect(institution.affiliations).to include(institution_affiliation)
          expect(institution.affiliations.count).to eq(0)
          expect(Greensub::InstitutionAffiliation.count).to eq(0)
        end
      end
    end
  end
end
