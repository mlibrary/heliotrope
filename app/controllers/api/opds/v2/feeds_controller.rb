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
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
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
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
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
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
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
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
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
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        private

          def javascript_escaping(hash_to_json)
            # https://www.thorntech.com/4-things-you-must-do-when-putting-html-in-json/
            #
            # https://jehiah.cz/a/guide-to-escape-sequences
            #
            # javascript escaping
            #
            # As part of web applications you are always outputting data into a <script> tag.
            # It’s important that all the values you output are escaped to prevent breaking
            # out of quoted strings, and from breaking the closing </script> tag.
            #
            # A good mental check is to think about breaking this code:
            #
            # <script>
            #     var a = "{{value}}";
            # </script>
            #
            # Typically this is done by JSON encoding all data output into the script tag.
            #
            # <script>
            #     var a = {{json_encode(value)}};
            # </script>
            #
            # Unfortunately this isn’t sufficient. It really surprises people, myself included,
            # that a properly escaped JSON string in a script tag that contains </script>
            # will break processing of the script block.
            #
            # For example, take this properly JSON encoded string:
            #
            # <script>
            #     var a = "</script><script>alert('and now i control your page');</script>";
            # </script>
            #
            # Notice you can break the script and double quoted string sandbox without a double quote!
            #
            # In a page served as XML it’s possible to guard against this by making the whole script tag
            # a PDATA block where you apply html escaping to the whole script contents,
            # but in XHTML/HTML mode that is not an option.
            #
            # The way to solve this is using backslash escape sequence for the forward slash.
            # (Note: some JSON encoders do this by default, some do not.)
            #
            #     / ==> \/
            #
            # However you can’t directly apply this substitution after JSON encoding
            # as this would break any existing backslash escapes. The following substitution
            # can however be used as a post-processing step after JSON encoding a string
            #
            #     </ ==> <\/
            #
            # In python you can do this with:
            #
            # return json.dumps(value).replace("</", "<\\/")

            # In Ruby to_json replaces '<' character with '\\u003c'
            # so you can do this with the return value:

            hash_to_json.gsub('\\u003c/', '\\u003c\\/')
          end

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
