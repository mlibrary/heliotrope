require 'active_support'
require 'active_support/core_ext/module'
require 'active_support/core_ext/object'

module IIIFManifest
  module V3
    extend ActiveSupport::Autoload
    autoload :ManifestBuilder
    autoload :ManifestFactory
    autoload :ManifestServiceLocator
    autoload :DisplayContent
  end
end
