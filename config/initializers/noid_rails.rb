# frozen_string_literal: true

# see HELIO-4360

::Noid::Rails.config.identifier_in_use = lambda do |id|
  ActiveFedora::Base.exists?(id) || ActiveFedora::Base.gone?(id)
end
