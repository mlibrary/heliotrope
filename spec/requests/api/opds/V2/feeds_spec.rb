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

  context "without entity_id" do
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
                  "title": "Big Ten Open Books",
                  "href": Rails.application.routes.url_helpers.api_opds_bigten_url,
                  "type": "application/opds+json"
                },
                {
                  "title": "Lever Press",
                  "href": Rails.application.routes.url_helpers.api_opds_leverpress_url,
                  "type": "application/opds+json"
                },
                {
                  "title": "ACLS Humanities Ebook",
                  "href": Rails.application.routes.url_helpers.api_opds_heb_url,
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
        let!(:amherst_product) { create(:product, identifier: "amherst") }
        let(:amherst_feed) do
          JSON.parse({
                      "metadata": {
                        "title": "Amherst College Press",
                        "currentPage": 1,
                        "itemsPerPage": 50,
                        "numberOfItems": 0
                      },
                      "links": [
                        {
                          "rel": "self",
                          "href": Rails.application.routes.url_helpers.api_opds_amherst_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "first",
                          "href": Rails.application.routes.url_helpers.api_opds_amherst_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "last",
                          "href": Rails.application.routes.url_helpers.api_opds_amherst_url(currentPage: 1),
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
            amherst_product.components << Greensub::Component.create(identifier: monograph.id, name: monograph.id, noid: monograph.id)
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

      describe "#bigten" do
        let!(:bigten_press) { create(:press, subdomain: "bigten") }
        let!(:bigten_product) { create(:product, identifier: "bigten") }
        let(:bigten_feed) do
          JSON.parse({
                      "metadata": {
                        "title": "Big Ten Open Books",
                        "currentPage": 1,
                        "itemsPerPage": 50,
                        "numberOfItems": 0
                      },
                      "links": [
                        {
                          "rel": "self",
                          "href": Rails.application.routes.url_helpers.api_opds_bigten_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "first",
                          "href": Rails.application.routes.url_helpers.api_opds_bigten_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "last",
                          "href": Rails.application.routes.url_helpers.api_opds_bigten_url(currentPage: 1),
                          "type": "application/opds+json"
                        }
                      ],
                      "publications": [
                      ]
                    }.to_json)
        end

        context "with no books" do
          it 'empty feed' do
            get api_opds_bigten_path, headers: headers
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body).to eq(bigten_feed)
            expect(response_body['publications']).to be_empty
          end
        end

        context 'with bigten books' do
          let(:monograph) { create(:public_monograph, press: bigten_press.subdomain) }
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
            bigten_product.components << Greensub::Component.create(identifier: monograph.id, name: monograph.id, noid: monograph.id)
          end

          it 'is non-empty' do
            get api_opds_bigten_path, headers: headers
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
        let!(:leverpress_product) { create(:product, identifier: "leverpress") }
        let(:leverpress_feed) do
          JSON.parse({
            "metadata": {
              "title": "Lever Press",
              "currentPage": 1,
              "itemsPerPage": 50,
              "numberOfItems": 0
            },
            "links": [
              {
                "rel": "self",
                "href": Rails.application.routes.url_helpers.api_opds_leverpress_url(currentPage: 1),
                "type": "application/opds+json"
              },
              {
                "rel": "first",
                "href": Rails.application.routes.url_helpers.api_opds_leverpress_url(currentPage: 1),
                "type": "application/opds+json"
              },
              {
                "rel": "last",
                "href": Rails.application.routes.url_helpers.api_opds_leverpress_url(currentPage: 1),
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
            leverpress_product.components << Greensub::Component.create(identifier: monograph.id, noid: monograph.id)
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
                        "title": "University of Michigan Press Ebook Collection",
                        "currentPage": 1,
                        "itemsPerPage": 50,
                        "numberOfItems": 0
                      },
                      "links": [
                        {
                          "rel": "self",
                          "href": Rails.application.routes.url_helpers.api_opds_umpebc_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "first",
                          "href": Rails.application.routes.url_helpers.api_opds_umpebc_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "last",
                          "href": Rails.application.routes.url_helpers.api_opds_umpebc_url(currentPage: 1),
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
                        "title": "University of Michigan Press Ebook Collection Open Access",
                        "currentPage": 1,
                        "itemsPerPage": 50,
                        "numberOfItems": 0
                      },
                      "links": [
                        {
                          "rel": "self",
                          "href": Rails.application.routes.url_helpers.api_opds_umpebc_oa_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "first",
                          "href": Rails.application.routes.url_helpers.api_opds_umpebc_oa_url(currentPage: 1),
                          "type": "application/opds+json"
                        },
                        {
                          "rel": "last",
                          "href": Rails.application.routes.url_helpers.api_opds_umpebc_oa_url(currentPage: 1),
                          "type": "application/opds+json"
                        }
                      ],
                      "publications": [
                      ]
                    }.to_json)
        end
        let!(:monograph_oa) { create(:public_monograph) }
        let!(:umpebc_product) { create(:product, identifier: "ebc_complete") }
        let!(:umpebc_oa_product) { create(:product, identifier: "ebc_oa") }

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

        context 'with publications' do
          let(:component) { create(:component, noid: monograph.id) }
          let(:component_oa) { create(:component, noid: monograph_oa.id) }
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
            umpebc_product.components << [component, component_oa]
            umpebc_oa_product.components << component_oa
          end

          it 'umpebc list all monographs' do
            get api_opds_umpebc_path, headers: headers
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body['publications'].count).to eq(2)
            expect(response_body['publications']).to contain_exactly(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id)).to_json), JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id)).to_json))
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

  context "with entity_id" do
    context "any product, OA or not (amherst OA here)" do
      let(:entity_id) { "https://shibboleth.umich.edu/idp/shibboleth" }
      let!(:amherst_press) { create(:press, subdomain: "amherst") }
      let!(:amherst_product) { create(:product, identifier: "amherst") }
      let(:amherst_feed) do
        JSON.parse({
                    "metadata": {
                      "title": "Amherst College Press",
                      "currentPage": 1,
                      "itemsPerPage": 50,
                      "numberOfItems": 0
                    },
                    "links": [
                      {
                        "rel": "self",
                        "href": Rails.application.routes.url_helpers.api_opds_amherst_url(currentPage: 1),
                        "type": "application/opds+json"
                      },
                      {
                        "rel": "first",
                        "href": Rails.application.routes.url_helpers.api_opds_amherst_url(currentPage: 1),
                        "type": "application/opds+json"
                      },
                      {
                        "rel": "last",
                        "href": Rails.application.routes.url_helpers.api_opds_amherst_url(currentPage: 1),
                        "type": "application/opds+json"
                      }
                    ],
                    "publications": [
                    ]
                  }.to_json)
      end

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
        amherst_product.components << Greensub::Component.create(identifier: monograph.id, noid: monograph.id)
      end

      it "returns wayfless download urls" do
        get api_opds_amherst_path, headers: headers, params: { filterByEntityId: entity_id }
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body['publications'].count).to eq(1)
        expect(response_body['publications'].first).to eq(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id), entity_id).to_json))
        expect(response_body['publications'].first["links"].first["href"]).to eq "http://test.host/ebooks/#{epub.id}/download?entityID=https%3A%2F%2Fshibboleth.umich.edu%2Fidp%2Fshibboleth"
      end
    end

    context "filters the feed to only accessible books (and all OA books)" do
      let(:entity_id) { "https://shibboleth.umich.edu/idp/shibboleth" }

      let(:monograph_2020) { create(:public_monograph) }
      let(:cover_2020) { create(:public_file_set) }
      let(:epub_2020) { create(:public_file_set) }
      let(:fr_2020) { create(:featured_representative, work_id: monograph_2020.id, file_set_id: epub_2020.id, kind: 'epub') }

      let(:monograph_2022) { create(:public_monograph) }
      let(:cover_2022) { create(:public_file_set) }
      let(:epub_2022) { create(:public_file_set) }
      let(:fr_2022) { create(:featured_representative, work_id: monograph_2022.id, file_set_id: epub_2022.id, kind: 'epub') }

      let(:monograph_oa) { create(:public_monograph) }
      let(:cover_oa) { create(:public_file_set) }
      let(:epub_oa) { create(:public_file_set) }
      let(:fr_oa) { create(:featured_representative, work_id: monograph_oa.id, file_set_id: epub_oa.id, kind: 'epub') }

      let(:product_backlist) { create(:product, identifier: 'ebc_complete') }
      let(:product_oa) { create(:product, identifier: 'ebc_oa') }
      let(:product_2020) { create(:product, identifier: 'ebc_2020') }
      let(:product_2022) { create(:product, identifier: 'ebc_2022') }

      let(:component_2020) { create(:component, noid: monograph_2020.id) }
      let(:component_2022) { create(:component, noid: monograph_2022.id) }
      let(:component_oa) { create(:component, noid: monograph_oa.id) }

      let(:institution) { create(:institution, entity_id: entity_id) }
      let(:institution_affiliation) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: institution.identifier) }

      before do
        monograph_2020.ordered_members << cover_2020
        monograph_2020.representative_id = cover_2020.id
        monograph_2020.ordered_members << epub_2020
        monograph_2020.date_modified = Time.now
        monograph_2020.save!
        cover_2020.save!
        epub_2020.save!
        fr_2020

        monograph_2022.ordered_members << cover_2022
        monograph_2022.representative_id = cover_2022.id
        monograph_2022.ordered_members << epub_2022
        monograph_2022.date_modified = Time.now
        monograph_2022.save!
        cover_2022.save!
        epub_2022.save!
        fr_2022

        monograph_oa.ordered_members << cover_oa
        monograph_oa.representative_id = cover_oa.id
        monograph_oa.ordered_members << epub_oa
        monograph_oa.date_modified = Time.now
        monograph_oa.open_access = 'yes'
        monograph_oa.save!
        cover_oa.save!
        epub_oa.save!
        fr_oa

        product_backlist.components << component_2020
        product_backlist.components << component_2022
        product_backlist.components << component_oa

        product_oa.components << component_oa

        product_2020.components << component_2020

        product_2022.components << component_2022

        # The institution is only subscribed to ebc_2020, not ebc_2022 or ebc_complete
        institution.create_product_license(product_2020)
      end

      it 'the institution only sees 2020 books and OA books, not 2022' do
        get api_opds_umpebc_path, headers: headers, params: { filterByEntityId: entity_id }
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body['publications'].count).to eq(2)
        expect(response_body['publications']).to contain_exactly(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_2020.id), entity_id).to_json),
                                                                 JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id), entity_id).to_json))
      end
    end
  end

  describe '#heb' do
    let!(:heb_press) { create(:press, subdomain: "heb") }
    let!(:heb_product) { create(:product, identifier: "heb") }
    let!(:heb_oa_product) { create(:product, identifier: "heb_oa") }
    let(:heb_feed) do
      JSON.parse({
        "metadata": {
          title: "ACLS Humanities Ebook",
          "currentPage": 1,
          "itemsPerPage": 50,
          "numberOfItems": 0
        },
        "links": [
          {
            "rel": "self",
            "href": Rails.application.routes.url_helpers.api_opds_heb_url(currentPage: 1),
            "type": "application/opds+json"
          },
          {
            "rel": "first",
            "href": Rails.application.routes.url_helpers.api_opds_heb_url(currentPage: 1),
            "type": "application/opds+json"
          },
          {
            "rel": "last",
            "href": Rails.application.routes.url_helpers.api_opds_heb_url(currentPage: 1),
            "type": "application/opds+json"
          }
        ],
        "publications": [
        ]
      }.to_json)
    end

    context "with no books" do
      it 'empty feed' do
        get api_opds_heb_path, headers: headers
        expect(response.content_type).to eq("application/opds+json")
        expect(response).to have_http_status(:ok)
        expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
        expect(response_body).to eq(heb_feed)
        expect(response_body['publications']).to be_empty
      end
    end

    context "with books" do
      let(:monograph) { create(:public_monograph, press: heb_press.subdomain) }
      let(:cover) { create(:public_file_set) }
      let(:epub) { create(:public_file_set) }
      let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

      let(:monograph_oa) { create(:public_monograph, press: heb_press.subdomain) }
      let(:cover_oa) { create(:public_file_set) }
      let(:epub_oa) { create(:public_file_set) }
      let(:fr_oa) { create(:featured_representative, work_id: monograph_oa.id, file_set_id: epub_oa.id, kind: 'epub') }

      let(:component) { create(:component, noid: monograph.id) }
      let(:component_oa) { create(:component, noid: monograph_oa.id) }

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
        monograph_oa.open_access = 'yes'
        monograph_oa.save!
        cover_oa.save!
        epub_oa.save!
        fr_oa

        heb_product.components << [component, component_oa]
        heb_oa_product.components << component_oa
      end

      context "with no entity_id" do
        it 'heb list all monographs' do
          get api_opds_heb_path, headers: headers
          expect(response.content_type).to eq("application/opds+json")
          expect(response).to have_http_status(:ok)
          expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
          expect(response_body['publications'].count).to eq(2)
          expect(response_body['publications']).to contain_exactly(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id)).to_json),
                                                                   JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id)).to_json))
        end
      end

      context "with an entity_id" do
        let(:entity_id) { "https://shibboleth.umich.edu/idp/shibboleth" }
        let(:institution) { create(:institution, entity_id: entity_id) }
        let(:institution_affiliation) { create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: institution.identifier) }

        context "when subscribed" do
          before { institution.create_product_license(heb_product) }

          it 'heb list all monographs' do
            get api_opds_heb_path, headers: headers, params: { filterByEntityId: entity_id }
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body['publications'].count).to eq(2)
            expect(response_body['publications']).to contain_exactly(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph.id), entity_id).to_json),
                                                                     JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id), entity_id).to_json))
          end
        end

        context "when not subscribed" do
          it 'heb list OA monographs' do
            get api_opds_heb_path, headers: headers, params: { filterByEntityId: entity_id }
            expect(response.content_type).to eq("application/opds+json")
            expect(response).to have_http_status(:ok)
            expect(schemer_validate?(opds_feed_schemer, response_body)).to be true
            expect(response_body['publications'].count).to eq(1)
            expect(response_body['publications']).to contain_exactly(JSON.parse(Opds::Publication.new_from_monograph(Sighrax.from_noid(monograph_oa.id), entity_id).to_json))
          end
        end
      end
    end
  end

  describe "pagination" do
    let!(:leverpress) { create(:press, subdomain: "leverpress") }
    let!(:leverpress_product) { create(:product, identifier: "leverpress") }
    let(:solr_response) do
      {
        "response": {
          "docs": []
        }
      }.with_indifferent_access
    end

    context "with 227 books in the product" do
      before do
        allow_any_instance_of(API::Opds::V2::FeedsController).to receive(:feed_solr_response).and_return([227, solr_response])
        allow_any_instance_of(API::Opds::V2::FeedsController).to receive(:publications).and_return([])
      end

      # page 1: 0-49
      # page 2: 50-99
      # page 3: 100-149
      # page 4: 150-200
      # page 5: 200-227

      context "the first page" do
        it "has the correct links" do
          get api_opds_leverpress_path, headers: headers

          expect(response).to have_http_status(:ok)
          expect(response_body['metadata']['title']).to eq "Lever Press"
          expect(response_body['metadata']['numberOfItems']).to eq 227
          expect(response_body['metadata']['itemsPerPage']).to eq 50
          expect(response_body['metadata']['currentPage']).to eq 1

          expect(response_body['links'].count).to eq(4)
          expect(response_body['links'][0]['rel']).to eq 'self'

          expect(response_body['links'][1]['rel']).to eq 'next'
          expect(response_body['links'][1]['href']).to eq "http://test.host/api/opds/leverpress?currentPage=2"

          expect(response_body['links'][2]['rel']).to eq 'first'

          expect(response_body['links'][3]['rel']).to eq 'last'
          expect(response_body['links'][3]['href']).to eq 'http://test.host/api/opds/leverpress?currentPage=5'
        end
      end

      context "the last page" do
        it "has the correct links (no next)" do
          get api_opds_leverpress_path, headers: headers, params: { currentPage: 5 }

          expect(response_body['links'].count).to eq(3)
          expect(response_body['links'][0]['rel']).to eq 'self'
          expect(response_body['links'][1]['rel']).to eq 'first'
          expect(response_body['links'][2]['rel']).to eq 'last'
        end
      end
    end
  end
end
