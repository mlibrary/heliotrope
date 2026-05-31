# -*- encoding: utf-8 -*-
require 'json/ld/reader'

module YAML_LD
  ##
  # A YAML-LD parser in Ruby.
  class Reader < JSON::LD::Reader
    format Format

    ##
    # Initializes the YAML-LD reader instance.
    #
    # @param  [IO, File, String]       input
    # @param [Proc] documentLoader
    #   The callback of the loader to be used to retrieve remote documents and contexts, and to parse IO objects.
    #   If specified, it must be used to retrieve remote documents and contexts; otherwise, if not specified, the processor's built-in loader must be used.
    #   The remote document returned must be parsed if it is YAML.
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize` and `JSON::LD::API.initialize`)
    # @yield  [reader] `self`
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise [RDF::ReaderError] if the JSON document cannot be loaded
    def initialize(input = $stdin,
      documentLoader: YAML_LD::API.method(:documentLoader),
      **options, &block)
      input = StringIO.new(input).tap do |d|
        d.define_singleton_method(:content_type) {'application/ld+yaml'}
      end if input.is_a?(String)
      super(input, documentLoader: documentLoader, **options, &block)
    end

    ##
    # @private
    # @see   RDF::Reader#each_statement
    def each_statement(&block)
      API.toRdf(@doc, **@options, &block)
    rescue ::Psych::SyntaxError, ::JSON::LD::JsonLdError => e
      log_fatal("Failed to parse input document: #{e.message}", exception: RDF::ReaderError)
    end
  end
end