# frozen_string_literal: true

ActionDispatch::Routing::UrlFor.module_eval do
  prepend(ActionDispatchRoutingUrlForOverride = Module.new do
    def url_for(options = nil)
      # Rails.logger.debug "url_for(" + options&.to_s + ")"
      super
    end
  end)
end
