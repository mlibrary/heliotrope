# frozen_string_literal: true
require 'active_support/core_ext/array/wrap'

module ActiveTriples
  ##
  # Module to include configurable class-wide properties common to
  # RDFSources.
  #
  # Define properties at the class level with:
  #
  # @example
  #   configure base_uri: "http://oregondigital.org/resource/",
  #     repository: :default
  #
  # Available properties are base_uri, rdf_label, type, and repository
  module Configurable
    def inherited(child_class)
      child_class.configure type: self.type
      super
    end

    def base_uri
      configuration[:base_uri]
    end

    def rdf_label
      configuration[:rdf_label]
    end

    def type
      configuration[:type]
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def repository
      configuration[:repository]
    end

    ##
    # API for configuring class properties on a RDFSource. This is an
    # alternative to overriding the methods in this module.
    #
    # Can configure the following values:
    #  - base_uri (allows passing slugs to the RDFSource initializer
    #    in place of fully qualified URIs)
    #  - rdf_label (overrides default label predicates)
    #  - type (a default rdf:type to include when initializing a
    #    new RDFSource)
    #  - repository (the target persist location to for the RDFSource)
    #
    # @example
    #   configure base_uri: "http://oregondigital.org/resource/", repository: :default
    #
    # @param options [Hash]
    def configure(options = {})
      options = options.map do |key, value|
        if self.respond_to?("transform_#{key}")
          value = self.__send__("transform_#{key}", value)
        end
        [key, value]
      end
      @configuration = configuration.merge(options)
    end

    def transform_type(values)
      Array.wrap(values).map do |value|
        RDF::URI.intern(value).tap do |uri|
          RDFSource.type_registry[uri] = self
        end
      end
    end
  end
end
