require 'iiif-image-api'
module Riiif
  class Engine < ::Rails::Engine
    require 'riiif/rails/routes'

    # How long to cache the tiles for.
    config.cache_duration = 3.days

    config.action_dispatch.rescue_responses['Riiif::ImageNotFoundError'] = :not_found

    # Set to true to use kdu for jp2000 source images
    config.kakadu_enabled = false

    # Set to true to use libvips to transform images
    # https://www.libvips.org/
    config.use_vips = false

    config.before_configuration do
      # see https://github.com/fxn/zeitwerk#for_gem
      # We put a generator into LOCAL APP lib/generators, so tell
      # zeitwerk to ignore the whole directory? If we're using a recent
      # enough version of Rails to have zeitwerk config
      #
      # See: https://github.com/cbeer/engine_cart/issues/117
      Rails.autoloaders.main.ignore(Rails.root.join('lib', 'generators')) if Rails.try(:autoloaders).try(:main).respond_to?(:ignore)
    end
  end
end
