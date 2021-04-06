# frozen_string_literal: true

module Sighrax
  class Platform
    private_class_method :new

    def tombstone_message(publisher)
      I18n.t('sighrax.platform.tombstone_message', publisher: publisher)
    end
  end
end
