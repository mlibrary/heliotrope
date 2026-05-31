# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  # Responsible for converting hashes from Solr into a {Valkyrie::Resource}
  class ORMConverter
    attr_reader :solr_document, :resource_factory

    # @param [Hash] solr_document
    # @param [ResourceFactory] resource_factory
    def initialize(solr_document, resource_factory:)
      @solr_document = solr_document
      @resource_factory = resource_factory
    end

    # Converts the Solr Document into a Valkyrie Resource
    # @return [Valkyrie::Resource]
    def convert!
      resource
    end

    # Construct the Valkyrie Resource using attributes derived from the Solr Document
    # @return [Valkyrie::Resource]
    def resource
      resource_klass.new(attributes.symbolize_keys.merge(new_record: false))
    end

    # Access the Class for the Valkyrie Resource
    # @return [Class]
    def resource_klass
      Valkyrie.config.resource_class_resolver.call(internal_resource)
    end

    # Access the String specifying the Valkyrie Resource type in the Solr Document
    # @return [String]
    def internal_resource
      solr_document.fetch(Valkyrie::Persistence::Solr::Queries::MODEL).first
    end

    # Derive the Valkyrie attributes from the Solr Document
    # @return [Hash]
    def attributes
      attribute_hash.merge("id" => id,
                           internal_resource: internal_resource,
                           created_at: created_at,
                           updated_at: updated_at,
                           Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK => token)
    end

    # Construct a Time object from the datestamp for the resource creation date indexed in Solr
    # @return [Time]
    def created_at
      DateTime.parse(solr_document.fetch("created_at_dtsi").to_s).new_offset(0)
    end

    # Construct a Time object from the datestamp for the date of the last resource update indexed in Solr
    # @return [Time]
    def updated_at
      DateTime.parse((solr_document["updated_at_dtsi"] || solr_document["timestamp"] || solr_document["created_at_dtsi"]).to_s).utc
    end

    # Construct the OptimisticLockToken object using the "_version_" field value in the Solr Document
    # @see https://lucene.apache.org/solr/guide/updating-parts-of-documents.html#optimistic-concurrency
    # @return [Valkyrie::Persistence::OptimisticLockToken]
    def token
      Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: resource_factory.adapter_id, token: version)
    end

    # Access the "_version_" field value within the Solr Document
    # @return [String]
    def version
      solr_document.fetch('_version_', nil)
    end

    # Retrieve the ID for the Valkyrie Resource in the Solr Document
    # @note this assumes that the ID has been prepended with the string "id-"
    # @return [String]
    def id
      solr_document.fetch('id').sub(/^id-/, '')
    end

    # Construct the Hash containing the Valkyrie Resource attributes using the Solr Document
    # @note this filters for attributes which have been indexed as stored multivalued texts (tsim)
    # @see https://github.com/samvera-labs/valkyrie/blob/main/solr/config/schema.xml
    # @see https://lucene.apache.org/solr/guide/defining-fields.html#defining-fields
    # @return [Hash]
    def attribute_hash
      build_literals(strip_tsim(solr_document.select do |k, _v|
        k.end_with?("tsim")
      end))
    end

    # Removes the substring "_tsim" within Hash keys
    # This is used when mapping Solr Document Hashes into Valkyrie Resource attributes
    # @see #attribute_hash
    # @param [Hash] hsh
    # @return [Hash]
    def strip_tsim(hsh)
      Hash[
        hsh.map do |k, v|
          [k.sub("_tsim", ""), v]
        end
      ]
    end

    # Class modeling a key/value pair within a Solr Document
    class Property
      attr_reader :key, :value, :document

      # @param [String] key
      # @param [String] value
      # @param [Hash] document
      def initialize(key, value, document)
        @key = key
        @value = value
        @document = document
      end
    end

    # Populates an existing Hash with SolrValue objects keyed to the existing Hash keys
    # @param [Hash] hsh
    # @return [Hash]
    def build_literals(hsh)
      hsh.each_with_object({}) do |(key, value), output|
        next if key.end_with?("_lang")
        next if key.end_with?("_type")
        output[key] = SolrValue.for(Property.new(key, value, hsh)).result
      end
    end

    # Abstract base class for values persisted in Solr
    class SolrValue < ::Valkyrie::ValueMapper
    end

    # Converts a stored language typed literal from two fields into one
    #   {RDF::Literal}
    class RDFLiteralPropertyValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a Property has a Solr Document specifying the language tag or type for the value
      # @param [Property] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) &&
          (value.document["#{value.key}_lang"] || value.document["#{value.key}_type"])
      end

      # Map the Property value to RDF literals
      # This ensures that, if possible, RDF::Literals are (re)constructed using language tags and datatypes
      # @return [Array<RDF::Literal>]
      def result
        value.value.each_with_index.map do |literal, idx|
          language = languages[idx]
          type = datatypes[idx]
          if language == "eng" && type == "http://www.w3.org/1999/02/22-rdf-syntax-ns#langString"
            literal
          elsif language.present?
            RDF::Literal.new(literal, language: language, datatype: type)
          else
            RDF::Literal.new(literal, datatype: type)
          end
        end
      end

      # Access the languages within the Solr field value
      # @note this assumes that the substring "_lang" is appended to the Solr field name specifying the supported language tags
      # @return [Array<String>]
      def languages
        value.document.fetch("#{value.key}_lang", [])
      end

      # Access the datatypes within the Solr field value
      # @note this assumes that the substring "_type" is appended to the Solr field name specifying the supported datatypes
      # @return [Array<String>]
      def datatypes
        value.document.fetch("#{value.key}_type", [])
      end
    end

    # Class for handling general string-serialized values in Solr fields
    class PropertyValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not an Object is a Property
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property)
      end

      # Constructs an EnumerableValue and accesses the String value
      # @return [String]
      def result
        calling_mapper.for(value.value).result
      end
    end

    # Class for handling multiple values in Solr fields
    class EnumerableValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a value behaves like an enumerable value
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.respond_to?(:each)
      end

      # Constructs SolrValue objects for each value and returns the String representation
      # For cases where there is only one value, only a single String is returned
      # @return [String, Array<String>]
      def result
        if value.length == 1
          calling_mapper.for(value.first).result
        else
          value.map do |element|
            calling_mapper.for(element).result
          end
        end
      end
    end

    # Converts a stored ID value in solr into a {Valkyrie::ID}
    class IDValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a string representation of an Object is prefixed with "id-"
      # @note this determines whether or not this should be mapped to a Valkyrie ID
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.to_s.start_with?("id-")
      end

      # Constructs a new Valkyrie::ID object using the ID parsed from the Solr field
      # @return [Valkyrie::ID]
      def result
        Valkyrie::ID.new(value.sub(/^id-/, ''))
      end
    end

    # Converts a stored URI value in solr into a {RDF::URI}
    class URIValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a string representation of an Object is prefixed with "uri-"
      # @note this determines whether or not this should be mapped to a URI
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.to_s.start_with?("uri-")
      end

      # Constructs a new RDF::URI object using the ID parsed from the Solr field
      # @return [RDF::URI]
      def result
        ::RDF::URI.new(value.sub(/^uri-/, ''))
      end
    end

    # Converts a nested resource in solr into a {Valkyrie::Resource}
    class NestedResourceValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a string representation of an Object is prefixed with "serialized-"
      # @note this determines whether or not this should be mapped to a Hash
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.to_s.start_with?("serialized-")
      end

      # Uses the NestedResourceConverter to parse the JSON-serialized Hash and convert this to a Valkyrie Resource attribute Hash
      # @return [Hash]
      def result
        NestedResourceConverter.for(JSON.parse(json, symbolize_names: true)).result
      end

      # Parses the JSON-serialized Hash value from the Solr field
      # @return [String]
      def json
        value.sub(/^serialized-/, '')
      end
    end

    # Abstract base class for handling nested Hashes (serializing resources in the RDF)
    class NestedResourceConverter < ::Valkyrie::ValueMapper
    end

    # Class for handling multiple serialized Hashes in Solr fields
    class NestedEnumerable < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)

      # Determines whether or not an Object is an Array
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Array)
      end

      # Uses the NestedResourceConverter to parse each element in the enumerable value, mapping the converted attributes to each
      # @return [Array<Hash>]
      def result
        value.map do |v|
          calling_mapper.for(v).result
        end
      end
    end

    # Class for handling serialized Hashes for Valkyrie IDs in Solr fields
    class NestedResourceID < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)

      # Determines whether or not an Object is a Property
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Hash) && value[:id] && !value[:internal_resource]
      end

      # Constructs a Valkyrie::ID object using the value keyed to :id in the Property Hash value
      # @return [Valkyrie::ID]
      def result
        Valkyrie::ID.new(value[:id])
      end
    end

    # Class for handling serialized Hashes for URIs in Solr fields
    class NestedResourceURI < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)

      # Determines whether or not an Object is a Hash with a URI string mapped to the "@id" key
      # @note this is used to determine whether or not this is a nested URI for an attribute
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Hash) && value[:@id]
      end

      # Constructs a RDF::URI object using the value keyed to :@id in the Property Hash value
      # @return [RDF::URI]
      def result
        RDF::URI(value[:@id])
      end
    end

    # Class for handling serialized Hashes for RDF literals in Solr fields
    class NestedResourceLiteral < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)

      # Determines whether or not an Object is a Hash with a string mapped to the "@value" key
      # @note this is used to determine whether or not this is a RDF literal for an attribute
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Hash) && value[:@value]
      end

      # Constructs a RDF::Literal object using the value keyed to :@value and language tag keyed to :@language in the Property Hash value
      # @return [RDF::URI]
      def result
        RDF::Literal.new(value[:@value], language: value[:@language])
      end
    end

    # Class for handling generic serialized Hashes in Solr fields
    class NestedResourceHash < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)

      # Determines whether or not an Object is a Hash
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Hash)
      end

      # Constructs a Hash mapping each converted Solr field value to the existing keys in the Property Hash value
      # @return [Hash]
      def result
        Hash[
          value.map do |k, v|
            [k, calling_mapper.for(v).result]
          end
        ]
      end
    end

    # Converts an boolean in solr into an {Boolean}
    class BooleanValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a string representation of an Object is prefixed with "boolean-"
      # @note this determines whether or not this should be mapped to a boolean value
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.to_s.start_with?("boolean-")
      end

      # Parses the Solr field value for the substring "true"
      # Should "true" be present, True is returned
      # @return [Boolean]
      def result
        val = value.sub(/^boolean-/, '')
        val.casecmp("true").zero?
      end
    end

    # Converts an integer in solr into an {Integer}
    class IntegerValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a string representation of an Object is prefixed with "integer-"
      # @note this determines whether or not this should be mapped to an integer
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.to_s.start_with?("integer-")
      end

      # Parses and casts the Solr field value into the integer value
      # @return [Integer]
      def result
        value.sub(/^integer-/, '').to_i
      end
    end

    # Converts a float in solr into a {Float}
    class FloatValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)
      def self.handles?(value)
        value.to_s.start_with?("float-")
      end

      def result
        value.sub(/^float-/, '').to_f
      end
    end

    # Converts a datetime in Solr into a {DateTime}
    class DateTimeValue < ::Valkyrie::ValueMapper
      SolrValue.register(self)

      # Determines whether or not a string representation of an Object is prefixed with "datetime-"
      # @note this determines whether or not this should be mapped to a DateTime object
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        return false unless value.to_s.start_with?("datetime-")
        DateTime.iso8601(value.sub(/^datetime-/, '')).new_offset(0)
      rescue
        false
      end

      # Parses and casts the Solr field value into a UTC DateTime value
      # @return [Time]
      def result
        DateTime.parse(value.sub(/^datetime-/, '')).new_offset(0)
      end
    end
  end
end
