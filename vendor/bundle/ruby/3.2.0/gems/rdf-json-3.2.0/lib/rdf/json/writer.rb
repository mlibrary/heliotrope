module RDF::JSON
  ##
  # RDF/JSON serializer.
  #
  # @example Loading RDF/JSON serialization support
  #   require 'rdf/json'
  #
  # @example Obtaining an RDF/JSON writer class
  #   RDF::Writer.for(:json)         #=> RDF::JSON::Writer
  #   RDF::Writer.for("etc/test.rj")
  #   RDF::Writer.for(:file_name      => "etc/test.rj")
  #   RDF::Writer.for(:file_extension => "rj")
  #   RDF::Writer.for(:content_type   => "application/rdf+json")
  #
  # @example Serializing RDF statements into an RDF/JSON file
  #   RDF::JSON::Writer.open("etc/test.rj") do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @example Serializing RDF statements into an RDF/JSON string
  #   RDF::JSON::Writer.buffer do |writer|
  #     graph.each_statement do |statement|
  #       writer << statement
  #     end
  #   end
  #
  # @see http://n2.talis.com/wiki/RDF_JSON_Specification
  class Writer < RDF::Writer
    format RDF::JSON::Format

    ##
    # Stores the RDF/JSON representation of a triple.
    #
    # @param  [RDF::Resource] subject
    # @param  [RDF::URI]      predicate
    # @param  [RDF::Value]    object
    # @return [void]
    # @see    #write_epilogue
    def write_triple(subject, predicate, object)
      s = subject.to_s
      p = predicate.to_s
      o = object.is_a?(RDF::Value) ? object : RDF::Literal.new(object)
      @json       ||= {}
      @json[s]    ||= {}
      @json[s][p] ||= []
      @json[s][p] << o.to_rdf_json
    end

    ##
    # Outputs the RDF/JSON representation of all stored triples.
    #
    # @return [void]
    # @see    #write_triple
    def write_epilogue
      puts @json.to_json
      super
    end

    ##
    # Returns the RDF/JSON representation of a blank node.
    #
    # @param  [RDF::Node] value
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_node(value, **options)
      value.to_rdf_json.to_json
    end

    ##
    # Returns the RDF/JSON representation of a URI reference.
    #
    # @param  [RDF::URI] value
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_uri(value, **options)
      value.to_rdf_json.to_json
    end

    ##
    # Returns the RDF/JSON representation of a literal.
    #
    # @param  [RDF::Literal, String, #to_s] value
    # @param  [Hash{Symbol => Object}] options
    # @return [String]
    def format_literal(value, **options)
      case value
        when RDF::Literal then value.to_rdf_json.to_json
        else RDF::Literal.new(value).to_rdf_json.to_json
      end
    end
  end # Writer
end # RDF::JSON
