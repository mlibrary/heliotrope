# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "OPDS Feeds", type: [:request, :json_schema]  do
  let(:headers) do
    {
        "ACCEPT" => "application/json, application/vnd.heliotrope.opds.v2+json",
    }
  end

  let(:current_user) { double('current_user', id: 'id', email: 'email') }
  let(:response_body) { JSON.parse(@response.body) }

  before do
    allow_any_instance_of(API::ApplicationController).to receive(:current_user).and_return(current_user)
    allow(User).to receive(:find).with(current_user.id).and_return(current_user)
  end

  it 'schemas are valid' do
    expect(schemer_validate?(meta_schemer, JSON.parse(Net::HTTP.get(URI('https://json-schema.org/draft-07/schema'))))).to be true
    expect(schemer_validate?(meta_schemer, JSON.parse(Net::HTTP.get(URI('https://drafts.opds.io/schema/feed.schema.json'))))).to be true
    expect(schemer_validate?(meta_schemer, JSON.parse(Net::HTTP.get(URI('https://drafts.opds.io/schema/publication.schema.json'))))).to be true
    expect(schemer_validate?(meta_schemer, JSON.parse(Net::HTTP.get(URI('https://readium.org/webpub-manifest/schema/extensions/presentation/metadata.schema.json'))))).to be true
  end

  context 'unauthorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_raise(StandardError) }

    describe '#opds' do
      let(:opds_feed) do
        JSON.parse(
          {
            "metadata": {
              "title": "Fulcrum OPDS Catalog"
          },
            "links": [
              {
                "rel": "self",
                "href": Rails.application.routes.url_helpers.api_opds_url,
                "type": "application/opds+json"
              }
            ],
            "navigation": [
              {
                "title": "Open Access Publications",
                "rel": "first",
                "href": "/oa",
                "type": "application/opds+json"
              }
            ]
          }.to_json)
      end

      it 'opds feed' do
        get api_opds_path, headers: headers
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body).to eq(opds_feed)
      end
    end

    describe '#open_access' do
      let(:open_access_feed) do
        JSON.parse({
          "metadata": {
            "title": "Fulcrum Open Access Publications"
          },
          "links": [
            {
              "rel": "self",
              "href": Rails.application.routes.url_helpers.api_opds_oa_url,
              "type": "application/opds+json"
            }
          ],
          "publications": [
          ]
        }.to_json)
      end
      let!(:monograph) { create(:public_monograph) }

      it 'empty feed' do
        get api_opds_oa_path, headers: headers
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body).to eq(open_access_feed)
        expect(response_body['publications']).to be_empty
      end

      context 'when invalid open access publication' do
        before do
          monograph.open_access = 'yes'
          monograph.save!
        end

        it 'is empty' do
          get api_opds_oa_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body['publications']).to be_empty
        end
      end

      context 'when valid open access publication' do
        let(:cover) { create(:public_file_set) }
        let(:epub) { create(:public_file_set) }
        let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

        before do
          monograph.ordered_members << cover
          monograph.representative_id = cover.id
          monograph.ordered_members << epub
          monograph.open_access = 'yes'
          monograph.save!
          cover.save!
          epub.save!
          fr
        end

        it 'is non-empty' do
          get api_opds_oa_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body['publications'].count).to eq(1)
          expect(response_body['publications'].first).to eq(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id)).to_json))
        end
      end
    end
  end
end
