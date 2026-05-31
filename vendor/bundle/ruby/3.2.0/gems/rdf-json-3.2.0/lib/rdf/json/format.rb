module RDF::JSON
  ##
  # RDF/JSON format specification.
  #
  # @example Loading RDF/JSON format support
  #   require 'rdf/json'
  #
  # @example Obtaining an RDF/JSON format class
  #   RDF::Format.for(:rj)         #=> RDF::JSON::Format
  #   RDF::Format.for("etc/doap.rj")
  #   RDF::Format.for(:file_name      => "etc/doap.rj")
  #   RDF::Format.for(:file_extension => "rj")
  #   RDF::Format.for(:content_type   => "application/rdf+json")
  #
  # @see http://n2.talis.com/wiki/RDF_JSON_Specification
  class Format < RDF::Format
    content_type     'application/rdf+json', :extension => :rj
    content_encoding 'utf-8'

    reader { RDF::JSON::Reader }
    writer { RDF::JSON::Writer }

    ##
     # Override normal symbol generation
     def self.to_sym
       :rj
     end

    require 'json'
  end # Format
end # RDF::JSON
