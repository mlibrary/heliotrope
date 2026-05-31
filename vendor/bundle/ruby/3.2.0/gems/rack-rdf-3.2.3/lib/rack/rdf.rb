require 'rack'
require 'rdf'
require 'rdf/ntriples'
require 'rdf/nquads'

module Rack
  module RDF
    autoload :ContentNegotiation, 'rack/rdf/conneg'
    autoload :VERSION,            'rack/rdf/version'

    ##
    # Registers all known RDF formats with Rack's MIME types registry.
    #
    # @param [Boolean]        overwrite (false)
    # @param  [Hash{Symbol => Object}] options
    # @return [void]
    def self.register_mime_types!(overwrite: false, **options)
      if defined?(Rack::Mime::MIME_TYPES)
        ::RDF::Format.each do |format|
          if !Rack::Mime::MIME_TYPES.has_key?(file_ext = ".#{format.to_sym}") || overwrite
            Rack::Mime::MIME_TYPES.merge!(file_ext => format.content_type.first)
          end
        end
        ::RDF::Format.file_extensions.each do |file_ext, formats|
          if !Rack::Mime::MIME_TYPES.has_key?(file_ext = ".#{file_ext}") || overwrite
            Rack::Mime::MIME_TYPES.merge!(file_ext => formats.first.content_type.first)
          end
        end
      end
    end
  end
end

Rack::RDF.register_mime_types!
