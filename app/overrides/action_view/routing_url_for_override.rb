# frozen_string_literal: true

ActionView::RoutingUrlFor.module_eval do
  prepend(ActionViewRoutingUrlForOverride = Module.new do
    def url_for(options = nil)
      rv = super

      if options
        case options[0]
        when ActionDispatch::Routing::RoutesProxy
          case options[1]
          when SolrDocument
            entity = Sighrax.from_solr_document(options[1])
            case entity
            when Sighrax::Monograph
              rv.sub!('monographs', 'oa-monographs') if entity.open_access?
            end
          end
        end
      end
      # Rails.logger.debug "routing_url_for(" + rv + ")"

      rv
    end
  end)
end
