module Rack; module LinkedData
  ##
  # Rack middleware for Linked Data content negotiation.
  #
  # Uses HTTP Content Negotiation to find an appropriate RDF
  # format to serialize any result with a body being `RDF::Enumerable`.
  #
  # Override content negotiation by setting the :format option to
  # `#initialize`.
  #
  # Add a :default option to set a content type to use when nothing else
  # is found.
  #
  # @example
  #     use Rack::LinkedData::ContentNegotation, :format => :ttl
  #     use Rack::LinkedData::ContentNegotiation, :format => RDF::NTriples::Format
  #     use Rack::LinkedData::ContentNegotiation, :default => 'application/rdf+xml'
  #
  # @see http://www4.wiwiss.fu-berlin.de/bizer/pub/LinkedDataTutorial/
  # @see https://www.rubydoc.info/github/rack/rack/master/file/SPEC
  class ContentNegotiation < Rack::RDF::ContentNegotiation
  end # class ContentNegotiation
end; end # module Rack::LinkedData
