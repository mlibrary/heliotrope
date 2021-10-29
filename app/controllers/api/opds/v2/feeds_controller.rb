# frozen_string_literal: true

module API
  # Namespace for the public facing OPDS feeds
  module Opds
    module V2
      # Feeds Controller
      class FeedsController < API::ApplicationController
        skip_before_action :authorize_request

        # This resource returns the root feed a.k.a. OPDS Catalog.
        # @example get /api/opds
        # @return [ActionDispatch::Response] { <opds_feed> }
        def opds
          feed = {
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
          }
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        # This resource returns the umpebc_oa publications feed.
        # @example get /api/opds/umpebc_oa
        # @return [ActionDispatch::Response] { <opds_feed> }
        def umpebc_oa
          feed = {
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
          }
          feed[:publications] = umpebc_oa_publications
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        # This resource returns the umpebc publications feed.
        # @example get /api/opds/umpebc
        # @return [ActionDispatch::Response] { <opds_feed> }
        def umpebc
          feed = {
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
          }
          feed[:publications] = umpebc_publications
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        # This resource returns the leverpress publications feed.
        # @example get /api/opds/leverpress
        # @return [ActionDispatch::Response] { <leverpress_feed> }
        def leverpress
          feed = {
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
          }
          feed[:publications] = publications_by_subdomain("leverpress")
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        # This resource returns the amherst publications feed.
        # @example get /api/opds/amherst
        # @return [ActionDispatch::Response] { <amherst_feed> }
        def amherst
          feed = {
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
          }
          feed[:publications] = publications_by_subdomain("amherst")
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        private

          def umpebc_oa_publications
            rvalue = []

            ebc_backlist = Greensub::Product.find_by(identifier: 'ebc_backlist')
            return rvalue if ebc_backlist.blank?

            monograph_noids = ebc_backlist.components.pluck(:noid)
            return rvalue if monograph_noids.blank?

            query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(monograph_noids)

            (ActiveFedora::SolrService.query(query, rows: monograph_noids.count, sort: "date_modified_dtsi desc") || []).each do |solr_doc|
              sm = ::Sighrax.from_solr_document(solr_doc)
              op = ::Opds::Publication.new_from_monograph(sm, true)
              rvalue.append(op.to_h) if op.valid?
            end

            rvalue
          end

          def umpebc_publications
            rvalue = []

            ebc_backlist = Greensub::Product.find_by(identifier: 'ebc_backlist')
            return rvalue if ebc_backlist.blank?

            monograph_noids = ebc_backlist.components.pluck(:noid)
            return rvalue if monograph_noids.blank?

            query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(monograph_noids)

            (ActiveFedora::SolrService.query(query, rows: monograph_noids.count, sort: "date_modified_dtsi desc") || []).each do |solr_doc|
              sm = ::Sighrax.from_solr_document(solr_doc)
              op = ::Opds::Publication.new_from_monograph(sm, false)
              rvalue.append(op.to_h) if op.valid?
            end

            rvalue
          end

          # Use this if the Press WILL ONLY EVER publish Open Access books.
          # So for instance Lever Press or Amherst Press.
          # (Although this will only return OA books due to Opds::Publication#valid?)
          # HELIO-3738
          def publications_by_subdomain(subdomain)
            rvalue = []

            (ActiveFedora::SolrService.query("+press_sim:#{subdomain} AND +visibility_ssi:open", rows: 100_000, sort: "date_modified_dtsi desc") || []).each do |solr_doc|
              sm = ::Sighrax.from_solr_document(solr_doc)
              op = ::Opds::Publication.new_from_monograph(sm, true)
              rvalue.append(op.to_h) if op.valid?
            end

            rvalue
          end
      end
    end
  end
end
