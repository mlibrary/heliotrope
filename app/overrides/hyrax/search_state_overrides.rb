# frozen_string_literal: true

Hyrax::SearchState.class_eval do
  prepend(HyraxSearchStateOverrides = Module.new do
    def url_for_document(doc, _options = {})
      # Rails.logger.debug "url_for_document(" + doc&.to_s + ', ' + _options&.to_s + ")"
      super
    end
  end)
end
