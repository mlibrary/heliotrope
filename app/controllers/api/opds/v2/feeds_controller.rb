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
          }
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        # This resource returns the umpebc_oa publications feed.
        # @example get /api/opds/umpebc_oa
        # @return [ActionDispatch::Response] { <opds_feed> }
        def umpebc_oa
          product_id = Greensub::Product.find_by(identifier: 'ebc_oa').id
          total, response = feed_solr_response([product_id])

          feed = {
            "metadata": {
              "title": "University of Michigan Press Ebook Collection Open Access",
              "numberOfItems": total,
              "itemsPerPage": 50,
              "currentPage": page
            },
            "links": [
            ],
            "publications": [
            ]
          }
          feed[:links] = feed_links(Rails.application.routes.url_helpers.api_opds_umpebc_oa_url, total, params[:filterByEntityId])
          feed[:publications] = publications(response["response"]["docs"], params[:filterByEntityId])
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        # This resource returns the umpebc publications feed.
        # @example get /api/opds/umpebc
        # @return [ActionDispatch::Response] { <opds_feed> }
        def umpebc
          entity_id = params[:filterByEntityId]
          # Default with no entity_id is ebc_complete or "everything" even if you can't read some of it.
          product_ids = [Greensub::Product.find_by(identifier: 'ebc_complete').id]
          if entity_id.present?
            # If you've got an entity_id you want to filter all of umpebc by what you're actually subcribed to.
            # But you also get all the OA books
            product_ids = ebc_subscribed_products(entity_id)
          end

          total, response = feed_solr_response(product_ids)

          feed = {
            "metadata": {
              "title": "University of Michigan Press Ebook Collection",
              "numberOfItems": total,
              "itemsPerPage": 50,
              "currentPage": page
            },
            "links": [
            ],
            "publications": [
            ]
          }
          feed[:links] = feed_links(Rails.application.routes.url_helpers.api_opds_umpebc_url, total, entity_id)
          feed[:publications] = publications(response["response"]["docs"], entity_id)
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        # This resource returns the heb publications feed.
        # @example get /api/opds/heb
        # @return [ActionDispatch::Response] { <opds_feed> }
        def heb
          # If you provide an entity_id and are subscribed, you get the heb product
          # If you provide an entity_id and are not subscribed, you get the heb_oa product
          # If you do not provide an entity_id, you get the heb product (but can't read the non-OA books)
          entity_id = params[:filterByEntityId]
          product_id = Greensub::Product.find_by(identifier: 'heb').id
          if entity_id.present? && !can_read_heb?(entity_id)
            product_id = Greensub::Product.find_by(identifier: 'heb_oa').id
          end

          total, response = feed_solr_response([product_id])

          feed = {
            "metadata": {
              "title": "ACLS Humanities Ebook",
              "numberOfItems": total,
              "itemsPerPage": 50,
              "currentPage": page
            },
            "links": [
            ],
            "publications": [
            ]
          }
          feed[:links] = feed_links(Rails.application.routes.url_helpers.api_opds_heb_url, total, entity_id)
          feed[:publications] = publications(response["response"]["docs"], entity_id)
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        # This resource returns the leverpress publications feed.
        # @example get /api/opds/leverpress
        # @return [ActionDispatch::Response] { <leverpress_feed> }
        def leverpress
          product_id = Greensub::Product.find_by(identifier: 'leverpress').id
          total, response = feed_solr_response([product_id])

          feed = {
            "metadata": {
              "title": "Lever Press",
              "numberOfItems": total,
              "itemsPerPage": 50,
              "currentPage": page
            },
            "links": [
            ],
            "publications": [
            ]
          }
          feed[:links] = feed_links(Rails.application.routes.url_helpers.api_opds_leverpress_url, total, params[:filterByEntityId])
          feed[:publications] = publications(response["response"]["docs"], params[:filterByEntityId])
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        # This resource returns the amherst publications feed.
        # @example get /api/opds/amherst
        # @return [ActionDispatch::Response] { <amherst_feed> }
        def amherst
          product_id = Greensub::Product.find_by(identifier: 'amherst').id
          total, response = feed_solr_response([product_id])

          feed = {
            "metadata": {
              "title": "Amherst College Press",
              "numberOfItems": total,
              "itemsPerPage": 50,
              "currentPage": page
            },
            "links": [
            ],
            "publications": [
            ]
          }

          feed[:links] = feed_links(Rails.application.routes.url_helpers.api_opds_amherst_url, total, params[:filterByEntityId])
          feed[:publications] = publications(response["response"]["docs"], params[:filterByEntityId])
          render plain: javascript_escaping(feed.to_json), content_type: 'application/opds+json'
        end

        private

          def feeds_params
            params.permit(:filterByEntityId, :currentPage)
          end

          def page
            params[:currentPage].present? ? params[:currentPage].to_i : 1
          end

          def start
            # page 1 then start = 0 (show 0 - 49)
            # page 2 then start = 50 (show 50 - 99)
            # page 3 then start = 100 (show 100 - 149)
            # page 4 then start = 150 (show 150 - 199)
            (page - 1) * 50
          end

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

          def feed_links(url, total, entity_id = nil)
            rel_self = url + "?currentPage=#{page}"
            rel_self += "&filterByEntityId=#{entity_id}" if entity_id.present?

            rel_first = url + "?currentPage=1"
            rel_first += "&filterByEntityId=#{entity_id}" if entity_id.present?

            rel_last = url + "?currentPage=#{(total / 50 < 1 ? 1 : total / 50 + 1)}"
            rel_last += "&filterByEntityId=#{entity_id}" if entity_id.present?

            rvalue = []
            rvalue << {
              "rel": "self",
              "href": rel_self,
              "type": "application/opds+json"
            }

            # I think don't show a next link if there's no next, right?
            if (page * 50) + 50 < total
              rel_next = url + "?currentPage=#{page + 1}"
              rel_next += "&filterByEntityId=#{entity_id}" if entity_id.present?

              rvalue << {
                "rel": "next",
                "href": rel_next,
                "type": "application/opds+json"
              }
            end

            rvalue << {
                "rel": "first",
                "href": rel_first,
                "type": "application/opds+json"
            }

            rvalue << {
                "rel": "last",
                "href": rel_last,
                "type": "application/opds+json"
            }

            rvalue
          end

          def ebc_subscribed_products(entity_id)
            product_ids = []
            institutions = Greensub::Institution.where(entity_id: entity_id)
            institutions.each do |inst|
              inst.products.each do |prod|
                # Get the products they're subscribed to
                product_ids << prod.id if prod.identifier.match?(/^ebc_/)
              end
            end
            # Add all the OA books
            product_ids << Greensub::Product.find_by(identifier: 'ebc_oa').id
          end

          def can_read_heb?(entity_id)
            can_read = false
            institutions = Greensub::Institution.where(entity_id: entity_id)
            institutions.each do |inst|
              inst.products.each do |prod|
                can_read = true if prod.identifier == "heb"
              end
            end
            can_read
          end

          def feed_solr_response(product_ids)
            response = ActiveFedora::SolrService.get("+has_model_ssim:Monograph AND +visibility_ssi:open AND +products_lsim:(#{product_ids.join(" ")}) AND -tombstone_ssim:yes", sort: "date_modified_dtsi desc", rows: 50, start: start)
            total = response["response"]["numFound"]
            return total, response
          end

          def publications(docs, entity_id = nil)
            rvalue = []
            docs.each do |solr_doc|
              sm = ::Sighrax.from_solr_document(solr_doc)
              op = ::Opds::Publication.new_from_monograph(sm, entity_id)
              rvalue.append(op.to_h)
            end
            rvalue
          end
      end
    end
  end
end
