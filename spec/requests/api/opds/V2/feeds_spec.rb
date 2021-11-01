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
                "title": "Amherst College Press",
                "href": Rails.application.routes.url_helpers.api_opds_amherst_url,
                "type": "application/opds+json"
              },
              {
                "title": "Lever Press",
                "href": Rails.application.routes.url_helpers.api_opds_leverpress_url,
                "type": "application/opds+json"
              },
              {
                "title": "University of Michigan Press Ebook Collection",
                "href": Rails.application.routes.url_helpers.api_opds_umpebc_url,
                "type": "application/opds+json"
              },
              {
                "title": "University of Michigan Press Ebook Collection Open Access",
                "href": Rails.application.routes.url_helpers.api_opds_umpebc_oa_url,
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

    describe '#amherst' do
      let!(:amherst_press) { create(:press, subdomain: "amherst") }
      let(:amherst_feed) do
        JSON.parse({
                     "metadata": {
                       "title": "Amherst College Press"
                     },
                     "links": [
                       {
                         "rel": "self",
                         "href": Rails.application.routes.url_helpers.api_opds_amherst_url,
                         "type": "application/opds+json"
                       }
                     ],
                     "publications": [
                     ]
                   }.to_json)
      end

      context "with no books" do
        it 'empty feed' do
          get api_opds_amherst_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body).to eq(amherst_feed)
          expect(response_body['publications']).to be_empty
        end
      end

      context 'with amherst books' do
        let(:monograph) { create(:public_monograph, press: amherst_press.subdomain) }
        let(:cover) { create(:public_file_set) }
        let(:epub) { create(:public_file_set) }
        let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

        before do
          monograph.ordered_members << cover
          monograph.representative_id = cover.id
          monograph.ordered_members << epub
          monograph.open_access = 'yes'
          monograph.date_modified = Time.now
          monograph.save!
          cover.save!
          epub.save!
          fr
        end

        it 'is non-empty' do
          get api_opds_amherst_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body['publications'].count).to eq(1)
          expect(response_body['publications'].first).to eq(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id)).to_json))
        end
      end
    end

    describe '#leverpress' do
      let!(:leverpress) { create(:press, subdomain: "leverpress") }
      let(:leverpress_feed) do
        JSON.parse({
          "metadata": {
            "title": "Lever Press"
          },
          "links": [
            {
              "rel": "self",
              "href": Rails.application.routes.url_helpers.api_opds_leverpress_url,
              "type": "application/opds+json"
            }
          ],
          "publications": [
          ]
        }.to_json)
      end

      context "with no books" do
        it 'empty feed' do
          get api_opds_leverpress_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body).to eq(leverpress_feed)
          expect(response_body['publications']).to be_empty
        end
      end

      context 'with leverpress books' do
        let(:monograph) { create(:public_monograph, press: leverpress.subdomain) }
        let(:cover) { create(:public_file_set) }
        let(:epub) { create(:public_file_set) }
        let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

        before do
          monograph.ordered_members << cover
          monograph.representative_id = cover.id
          monograph.ordered_members << epub
          monograph.open_access = 'yes'
          monograph.date_modified = Time.now
          monograph.save!
          cover.save!
          epub.save!
          fr
        end

        it 'is non-empty' do
          get api_opds_leverpress_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body['publications'].count).to eq(1)
          expect(response_body['publications'].first).to eq(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id)).to_json))
        end
      end
    end

    describe '#umpebc and #umpebc_oa' do
      let(:umpebc_feed) do
        JSON.parse({
                     "metadata": {
                       "title": "University of Michigan Press Ebook Collection"
                     },
                     "links": [
                       {
                         "rel": "self",
                         "href": Rails.application.routes.url_helpers.api_opds_umpebc_url,
                         "type": "application/opds+json"
                       }
                     ],
                     "publications": [
                     ]
                   }.to_json)
      end
      let!(:monograph) { create(:public_monograph) }
      let(:umpebc_oa_feed) do
        JSON.parse({
                     "metadata": {
                       "title": "University of Michigan Press Ebook Collection Open Access"
                     },
                     "links": [
                       {
                         "rel": "self",
                         "href": Rails.application.routes.url_helpers.api_opds_umpebc_oa_url,
                         "type": "application/opds+json"
                       }
                     ],
                     "publications": [
                     ]
                   }.to_json)
      end
      let!(:monograph_oa) { create(:public_monograph) }

      before do
        monograph_oa.open_access = 'yes'
        monograph_oa.save!
      end

      it 'umpebc empty feed' do
        get api_opds_umpebc_path, headers: headers
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body).to eq(umpebc_feed)
        expect(response_body['publications']).to be_empty
      end

      it 'umpebc_oa empty feed' do
        get api_opds_umpebc_oa_path, headers: headers
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body).to eq(umpebc_oa_feed)
        expect(response_body['publications']).to be_empty
      end

      context 'ebc backlist' do
        let(:product) { create(:product, identifier: 'ebc_backlist') }
        let(:component) { create(:component, noid: monograph.id) }
        let(:component_oa) { create(:component, noid: monograph_oa.id) }

        before do
          product.components << component
          product.components << component_oa
        end

        context 'when invalid publications' do
          it 'umpebc empty feed' do
            get api_opds_umpebc_path, headers: headers
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body).to eq(umpebc_feed)
            expect(response_body['publications']).to be_empty
          end

          it 'umpebc_oa empty feed' do
            get api_opds_umpebc_oa_path, headers: headers
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body).to eq(umpebc_oa_feed)
            expect(response_body['publications']).to be_empty
          end
        end

        context 'when valid publications' do
          let(:cover) { create(:public_file_set) }
          let(:epub) { create(:public_file_set) }
          let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
          let(:cover_oa) { create(:public_file_set) }
          let(:epub_oa) { create(:public_file_set) }
          let(:fr_oa) { create(:featured_representative, work_id: monograph_oa.id, file_set_id: epub_oa.id, kind: 'epub') }

          before do
            monograph.ordered_members << cover
            monograph.representative_id = cover.id
            monograph.ordered_members << epub
            monograph.date_modified = Time.now
            monograph.save!
            cover.save!
            epub.save!
            fr
            monograph_oa.ordered_members << cover_oa
            monograph_oa.representative_id = cover_oa.id
            monograph_oa.ordered_members << epub_oa
            monograph_oa.date_modified = Time.now
            monograph_oa.save!
            cover_oa.save!
            epub_oa.save!
            fr_oa
          end

          it 'umpebc list all monographs' do
            get api_opds_umpebc_path, headers: headers
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body['publications'].count).to eq(2)
            expect(response_body['publications']).to contain_exactly(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id), false).to_json), JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id), false).to_json))
          end

          it 'umpebc_oa list only open access monographs' do
            get api_opds_umpebc_oa_path, headers: headers
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body['publications'].count).to eq(1)
            expect(response_body['publications'].first).to eq(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id)).to_json))
          end
        end
      end
    end
  end
end
