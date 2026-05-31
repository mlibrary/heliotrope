require 'rack/rdf'
require 'linkeddata'

module Rack
  module LinkedData
    autoload :ContentNegotiation, 'rack/linkeddata/conneg'
    autoload :VERSION,            'rack/linkeddata/version'

    ##
    # Registers all known RDF formats with Rack's MIME types registry.
    #
    # @param [Boolean]        overwrite (false)
    # @param  [Hash{Symbol => Object}] options
    # @return [void]
    def self.register_mime_types!(overwrite: false, **options)
      Rack::RDF.register_mime_types!(overwrite: overwrite, **options)
    end
  end
end

Rack::LinkedData.register_mime_types!
