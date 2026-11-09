# frozen_string_literal: true

# NOTE: since Rails 7 the Zeitwerk autoloader is only set up *after*
# `config/initializers` are loaded, so autoloadable constants have to be
# referenced from a `to_prepare` block rather than required here.
Rails.application.config.to_prepare do
  Greensub
end
