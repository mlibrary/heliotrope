# frozen_string_literal: true

module EPubHelper
  # Rails present?, blank?, and other stuff...
  require 'active_support'
  require 'active_support/core_ext'

  # Heliotrope EPubs Services
  require_relative '../../../app/services/e_pubs_service'
  require_relative '../../../app/services/e_pubs_search_service'

  # EPub Module
  require_relative '../../../lib/e_pub'

  # Use this setup block to configure all options available in EPub.
  EPub.configure do |config|
  end
end
