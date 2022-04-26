# frozen_string_literal: true

module Hyrax
  module Renderers
    class MonographFacetAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          if options[:markdown]
            link_to(MarkdownService.markdown(value), search_path(value))
          else
            link_to(ERB::Util.h(value), search_path(value))
          end
        end

        def search_path(value)
          Rails.application.routes.url_helpers.monograph_catalog_path(
            id: options[:monograph_id], "f[#{search_field}][]": value
          )
        end

        def search_field
          "#{options.fetch(:search_field, field)}_sim"
        end
    end
  end
end
