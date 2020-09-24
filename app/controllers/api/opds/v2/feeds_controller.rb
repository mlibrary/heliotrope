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
                "title": "Open Access Publications",
                "rel": "first",
                "href": "/oa",
                "type": "application/opds+json"
              }
            ]
          }
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        # This resource returns the open access feed.
        # @example get /api/opds/oa
        # @return [ActionDispatch::Response] { <opds_feed> }
        def open_access
          feed = {
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
          }
          feed[:publications] = open_access_publications
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        private

          def open_access_publications
            rvalue = []
            (ActiveFedora::SolrService.query(
              "+has_model_ssim:Monograph AND +visibility_ssi:open AND -suppressed_bsi:true AND +open_access_tesim:yes",
              rows: 100_000
            ) || [])
              .each do |solr_doc|
                sm = ::Sighrax.from_solr_document(solr_doc)
                op = ::Opds::Publication.new_from_monograph(sm)
                rvalue.append(op.to_h) if op.valid?
              end
            rvalue
          end
      end
    end
  end
end
