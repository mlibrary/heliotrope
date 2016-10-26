module CurationConcerns
  module Renderers
    class FacetedAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          link_to(ERB::Util.h(value), search_path(value))
        end

        def search_path(value)
          Rails.application.routes.url_helpers.monograph_catalog_path(
            id: options[:monograph_id], :"f[#{search_field}][]" => ERB::Util.h(value))
        end

        def search_field
          ERB::Util.h(Solrizer.solr_name(options.fetch(:search_field, field), :facetable, type: :string))
        end
    end
  end
end
