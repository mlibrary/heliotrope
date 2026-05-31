require 'iiif_manifest/version'
require 'active_support'
require 'active_support/core_ext/module'
require 'active_support/core_ext/object'

module IIIFManifest
  extend ActiveSupport::Autoload
  autoload :Configuration
  autoload :ManifestBuilder
  autoload :ManifestFactory
  autoload :ManifestServiceLocator
  autoload :DisplayImage
  autoload :IIIFCollection
  autoload :IIIFEndpoint
  autoload :V3

  ##
  # @api public
  #
  # Exposes the IIIFManifest configuration.
  #
  # In the below examples, you would add the code to a `config/initializers/iiif_manifest_config.rb` file
  # in your application.
  #
  # @example
  #   # obliterate the default configuration and only use the one we gave
  #   IIIFManifest.config do |config|
  #     config.manifest_property_to_record_method_name_map = { summary: :abstract }
  #   end
  #
  #   # use the default configuration but amend the summary property
  #   IIIFManifest.config do |config|
  #     config.manifest_property_to_record_method_name_map.merge!(summary: :abstract)
  #   end
  #
  #   # set max edge length for thumbnail images
  #   # the below example will set the max edge to 100px
  #   IIIFManifest.confg do |config|
  #     config.max_edge_for_thumbnail = 100
  #   end
  #
  #   # disable the thumbnail property on the manifest level
  #   # since it will be shown by default
  #   IIIFManifest.confg do |config|
  #     config.manifest_thumbnail = false
  #   end
  #
  # @yield [IIIFManifest::Configuration] if a block is passed
  # @return [IIIFManifest::Configuration]
  # @see IIIFManifest::Configuration for configuration options
  def self.config(&block)
    @config ||= IIIFManifest::Configuration.new

    yield @config if block

    @config
  end
end
