require 'riiif/version'
require 'deprecation'
require 'riiif/engine'
module Riiif
  extend ActiveSupport::Autoload
  autoload :Routes

  class Error < RuntimeError; end
  class InvalidAttributeError < Error; end
  class ImageNotFoundError < Error; end

  # This error is raised when Riiif can't convert an image
  class ConversionError < Error; end

  def self.deprecation
    @deprecation ||= ActiveSupport::Deprecation.new('3.0', 'Riiif')
  end

  HTTPFileResolver = ActiveSupport::Deprecation::DeprecatedConstantProxy.new(
    'Riiif::HTTPFileResolver',
    'Riiif::HttpFileResolver',
    Riiif.deprecation
  )

  mattr_accessor :not_found_image # the image to use when a lookup fails
  mattr_accessor :unauthorized_image # the image to use when a user doesn't have access

  def self.kakadu_enabled?
    Engine.config.kakadu_enabled
  end

  def self.use_vips?
    Engine.config.use_vips
  end
end
