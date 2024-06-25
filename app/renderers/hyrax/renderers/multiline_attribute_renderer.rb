# frozen_string_literal: true

require "rails_autolink/helpers"

module Hyrax
  module Renderers
    class MultilineAttributeRenderer < AttributeRenderer
      # override to preserve newlines
      def li_value(value)
        # CC's usage:
        # auto_link(ERB::Util.h(value))
        ERB::Util.h(value).gsub(/\r\n?|\n/, '<br>')
      end
    end
  end
end
