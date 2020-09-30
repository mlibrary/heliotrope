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
                "title": "University of Michigan Press Ebook Collection Open Access",
                "rel": "first",
                "href": "/ebc_open",
                "type": "application/opds+json"
              }
            ]
          }
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        # This resource returns the open access feed.
        # @example get /api/opds/oa
        # @return [ActionDispatch::Response] { <opds_feed> }
        def ebc_open
          feed = {
            "metadata": {
              "title": "University of Michigan Press Ebook Collection Open Access"
            },
            "links": [
              {
                "rel": "self",
                "href": Rails.application.routes.url_helpers.api_opds_ebc_open_url,
                "type": "application/opds+json"
              }
            ],
            "publications": [
            ]
          }
          feed[:publications] = ebc_open_publications
          render plain: feed.to_json, content_type: 'application/opds+json'
        end

        private

          def ebc_open_publications
            ebc_open = Greensub::Product.find_by(identifier: 'ebc_open')
            return [] if ebc_open.blank?

            monograph_noids = ebc_open.components.pluck(:noid)
            return [] if monograph_noids.blank?

            query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(monograph_noids)

            rvalue = []
            (ActiveFedora::SolrService.query(query, rows: monograph_noids.count) || []).each do |solr_doc|
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
