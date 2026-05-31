# frozen_string_literal: true
module ActiveTriples
  require_relative 'configuration/item'
  require_relative 'configuration/merge_item'
  require_relative 'configuration/item_factory'

  ##
  # Class which contains configuration for RDFSources.
  class Configuration
    attr_accessor :inner_hash

    ##
    # @param item_factory [ItemFactory]
    # @param [Hash] options the configuration options. (Ruby 3+)
    # @param [Hash] options2 the configuration options. (Ruby 2.x)
    def initialize(options = {}, item_factory: ItemFactory.new, **options2)
      @item_factory = item_factory
      @inner_hash   = Hash[options.to_a + options2.to_a]
    end

    ##
    # Merges this configuration with other configuration options. This uses
    # reflection setters to handle special cases like :type.
    #
    # @param [Hash] options configuration options to merge in.
    # @return [ActiveTriples::Configuration] the configuration object which is a
    #   result of merging.
    def merge(options)
      options    = options.to_h
      new_config = self.class.new(options)

      new_config.items.each do |property, item|
        build_configuration_item(property).set item.value
      end

      self
    end

    ##
    # Returns a hash with keys as the configuration property and values as
    # reflections which know how to set a new value to it.
    #
    # @return [Hash{Symbol => ActiveTriples::Configuration::Item}]
    def items
      to_h.each_with_object({}) do |config_value, hsh|
        key = config_value.first
        hsh[key] = build_configuration_item(key)
      end
    end

    ##
    # Returns the configured value for an option
    #
    # @return the configured value
    def [](value)
      to_h[value]
    end

    ##
    # Returns the available configured options as a hash.
    #
    # This filters the options the class is initialized with.
    #
    # @return [Hash{Symbol => String, ::RDF::URI}]
    def to_h
      inner_hash.slice(*valid_config_options)
    end

    protected

    def build_configuration_item(key)
      item_factory.new(self, key)
    end

    private
    
    CONFIG_OPTIONS = [:base_uri, :rdf_label, :type, :repository].freeze
    
    attr_reader :item_factory

    def valid_config_options
      CONFIG_OPTIONS
    end
  end
end
