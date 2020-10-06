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
                "href": "/umpebc_oa",
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

        private

          def umpebc_oa_publications
            ebc_backlist = Greensub::Product.find_by(identifier: 'ebc_backlist')
            return [] if ebc_backlist.blank?

            monograph_noids = ebc_backlist.components.pluck(:noid)
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
