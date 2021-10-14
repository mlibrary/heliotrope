# frozen_string_literal: true

module Hyrax
  module Renderers
    class CatalogFacetAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          if options[:markdown]
            link_to(MarkdownService.markdown(value), search_path(value))
          else
            link_to(ERB::Util.h(value), search_path(value))
          end
        end

        def search_path(value)
          "/#{options[:subdomain]}?f[#{search_field}][]=#{CGI.escape value}&locale=#{I18n.locale}"
          # FIXME: this does not work with any combination of parameters currently
          # because of our oddball catch-all press routes.
          # Rails.application.routes.url_helpers.press_catalog_path(
          #  subdomain => options[:subdomain],
          #  :"f[#{search_field}][]" => value
          # )
        end

        def search_field
          Solrizer.solr_name(options.fetch(:search_field, field), :facetable, type: :string)
        end
    end
  end
end
