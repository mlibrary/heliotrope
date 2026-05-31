module RDF::JSON
  ##
  # RDF/JSON extensions for [RDF.rb](https://github.com/ruby-rdf/rdf) core classes
  # and mixins.
  #
  # Classes are extended with two new instance methods:
  #
  # * `#to_rdf_json` returns the RDF/JSON representation as a `Hash` object.
  # * `#to_rdf_json.to_json` returns the serialized RDF/JSON representation as a string.
  #
  # @example Serializing blank nodes into RDF/JSON format
  #   RDF::Node.new(id).to_rdf_json.to_json
  #
  # @example Serializing URI references into RDF/JSON format
  #   RDF::URI.new("https://rubygems.org/gems/rdf/").to_rdf_json.to_json
  #
  # @example Serializing plain literals into RDF/JSON format
  #   RDF::Literal.new("Hello, world!").to_rdf_json.to_json
  #
  # @example Serializing language-tagged literals into RDF/JSON format
  #   RDF::Literal.new("Hello, world!", :language => 'en-US').to_rdf_json.to_json
  #
  # @example Serializing datatyped literals into RDF/JSON format
  #   RDF::Literal.new(3.1415).to_rdf_json.to_json
  #   RDF::Literal.new('true', :datatype => RDF::XSD.boolean).to_rdf_json.to_json
  #
  # @example Serializing statements into RDF/JSON format
  #   RDF::Statement.new(s, p, o).to_rdf_json.to_json
  #
  # @example Serializing enumerables into RDF/JSON format
  #   [RDF::Statement.new(s, p, o)].extend(RDF::Enumerable).to_rdf_json.to_json
  #
  module Extensions
    ##
    # @private
    def self.install!
      self.constants.each do |klass|
        RDF.const_get(klass).send(:include, self.const_get(klass))
      end
    end

    ##
    # RDF/JSON extensions for `RDF::Node`.
    module Node
      ##
      # Returns the RDF/JSON representation of this blank node.
      #
      # @return [Hash]
      def to_rdf_json
        {:type => :bnode, :value => to_s}
      end
    end # Node

    ##
    # RDF/JSON extensions for `RDF::URI`.
    module URI
      ##
      # Returns the RDF/JSON representation of this URI reference.
      #
      # @return [Hash]
      def to_rdf_json
        {:type => :uri, :value => to_s}
      end
    end # URI

    ##
    # RDF/JSON extensions for `RDF::Literal`.
    module Literal
      ##
      # Returns the RDF/JSON representation of this literal.
      #
      # @return [Hash]
      def to_rdf_json
        case
          when has_datatype?
            {:type => :literal, :value => value.to_s, :datatype => datatype.to_s}
          when has_language?
            {:type => :literal, :value => value.to_s, :lang => language.to_s}
          else
            {:type => :literal, :value => value.to_s}
        end
      end
    end # Literal

    ##
    # RDF/JSON extensions for `RDF::Statement`.
    module Statement
      ##
      # Returns the RDF/JSON representation of this statement.
      #
      # @return [Hash]
      def to_rdf_json
        {subject.to_s => {predicate.to_s => [object.to_rdf_json]}}
      end
    end # Statement

    ##
    # RDF/JSON extensions for `RDF::Enumerable`.
    module Enumerable
      ##
      # Returns the RDF/JSON representation of this object.
      #
      # @return [Hash]
      def to_rdf_json
        json = {}
        each_statement do |statement|
          s = statement.subject.to_s
          p = statement.predicate.to_s
          o = statement.object.is_a?(RDF::Value) ? statement.object : RDF::Literal.new(statement.object)
          json[s]    ||= {}
          json[s][p] ||= []
          json[s][p] << o.to_rdf_json
        end
        json
      end
    end # Enumerable

    ##
    # RDF/JSON extensions for `RDF::Graph`.
    module Graph
      include Enumerable
    end # Graph

    ##
    # RDF/JSON extensions for `RDF::Repository`.
    module Repository
      include Enumerable
    end # Repository

    ##
    # RDF/JSON extensions for `RDF::Transaction`.
    module Transaction
      ##
      # Returns the serialized RDF/JSON representation of this object.
      #
      # @return [Hash]
      def to_rdf_json
        json = options.dup.to_hash rescue {}
        json.merge!({
          :graph  => graph ? graph.to_uri.to_s : nil,
          :delete => deletes.to_rdf_json,
          :insert => inserts.to_rdf_json,
        })
      end
    end # Transaction
  end # Extensions

  Extensions.install!
end # RDF::JSON
