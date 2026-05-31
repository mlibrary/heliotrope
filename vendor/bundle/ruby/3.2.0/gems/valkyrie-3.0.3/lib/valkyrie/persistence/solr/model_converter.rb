# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  # Responsible for converting a {Valkyrie::Resource} into hashes for indexing
  # into Solr.
  class ModelConverter
    attr_reader :resource, :resource_factory
    delegate :resource_indexer, to: :resource_factory

    # @param [Valkyrie::Resource] resource
    # @param [ResourceFactory] resource_factory
    def initialize(resource, resource_factory:)
      @resource = resource
      @resource_factory = resource_factory
    end

    # Converts the Valkyrie Resource to the Solr Document
    # @note this modifies the Solr Document for the conversion
    # @return [Hash] the Solr Document for the Valkyrie Resource
    def convert!
      # Appends the resource type to the Solr Document
      to_h.merge(Valkyrie::Persistence::Solr::Queries::MODEL.to_sym => [resource.internal_resource])
          .merge(indexer_solr(resource))
    end

    # Generate the Solr Document for a Valkyrie Resource using the indexer
    # @param [Valkyrie::Resource] resource
    # @return [Hash] the Solr Document as a Hash
    def indexer_solr(resource)
      resource_indexer.new(resource: resource).to_solr
    end

    # Access the ID for the Valkyrie Resource being converted to a Solr Document
    # @return [String] The solr document ID
    def id
      resource.id.to_s
    end

    # @return [String] ISO-8601 timestamp in UTC of the created_at for this solr
    #   document.
    def created_at
      if resource_attributes[:created_at]
        DateTime.parse(resource_attributes[:created_at].to_s).utc.iso8601
      else
        Time.current.utc.iso8601(6)
      end
    end

    # @return [String] ISO-8601 timestamp in UTC of the updated_at for solr
    # @note Solr stores its own updated_at timestamp, but for performance
    # reasons we're generating our own. Without doing so, every time we add a
    # new document we'd have to do a GET to find out the timestamp.
    def updated_at
      Time.current.utc.iso8601(6)
    end

    # @return [Hash] Solr document to index.
    def to_h
      {
        "id": id,
        "join_id_ssi": "id-#{id}",
        "created_at_dtsi": created_at,
        "updated_at_dtsi": updated_at
      }.merge(add_single_values(attribute_hash)).merge(lock_hash)
    end

    private

    # Maps Solr Document fields to attributes with single values
    # Filters for fields which store the Valkyrie resource type
    # @param [Hash] attribute_hash
    # @return [Hash]
    def add_single_values(attribute_hash)
      attribute_hash.select do |k, v|
        field = k.to_s.split("_").last
        property = k.to_s.gsub("_#{field}", "")
        next true if multivalued?(field)
        next false if property == "internal_resource"
        next false if v.length > 1
        true
      end
    end

    # Determines whether or not a field is multivalued
    # @note this is tied to conventions in the Solr Schema
    # @see https://github.com/samvera-labs/valkyrie/blob/main/solr/config/schema.xml
    # @see https://lucene.apache.org/solr/guide/defining-fields.html#defining-fields
    # @param [String] field
    # @return [Boolean]
    def multivalued?(field)
      field.end_with?('m', 'mv')
    end

    # If optimistic locking is enabled for this Valkyrie Resource, generates a Hash containing the locking token
    # @return [Hash]
    def lock_hash
      return {} unless resource.optimistic_locking_enabled? && lock_token.present?
      { _version_: lock_token }
    end

    # Retrieves the lock token from the resource attributes
    # @return [String]
    def lock_token
      @lock_token ||= begin
        found_token = resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
                      .find { |token| token.adapter_id == resource_factory.adapter_id }
        return if found_token.nil?
        found_token.token
      end
    end

    # Generates the Valkyrie Resource attribute Hash
    # @return [Hash]
    def attribute_hash
      properties.each_with_object({}) do |property, hsh|
        next if property == Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK
        attr = resource_attributes[property]
        next if attr.nil?
        mapper_val = SolrMapperValue.for(Property.new(property, attr)).result
        unless mapper_val.respond_to?(:apply_to)
          raise "Unable to cast #{resource_attributes[:internal_resource]}#" \
                "#{property} which has been set to an instance of '#{attr.class}'"
        end
        mapper_val.apply_to(hsh)
      end
    end

    # Accesses the keys for the attributes on the Valkyrie Resource
    # @return [Array<Symbol>]
    def properties
      resource_attributes.keys - [:id, :created_at, :updated_at, :new_record]
    end

    # Access the attributes for the Valkyrie resources
    # @return [Hash]
    def resource_attributes
      @resource_attributes ||= resource.attributes
    end

    ##
    # A container resource for holding a `key`, `value, and `scope` of a value
    # in a resource together for casting.
    class Property
      attr_reader :key, :value, :scope
      # @param key [Symbol] Property identifier.
      # @param value [Object] Value or list of values which are underneath the
      #   key.
      # @param scope [Object] The resource or point where the key and values
      #   came from.
      def initialize(key, value, scope = [])
        @key = key
        @value = value
        @scope = scope
      end
    end

    ##
    # Represents a key/value combination in the solr document, used for isolating logic around
    # how to apply a value to a hash.
    class SolrRow
      attr_reader :key, :fields, :values
      # @param key [Symbol] Solr key.
      # @param fields [Array<Symbol>] Field suffixes to index into.
      # @param values [Array] Values to index into the given fields.
      def initialize(key:, fields:, values:)
        @key = key
        @fields = fields
        @values = values
      end

      # @param hsh [Hash] The solr hash to apply to.
      # @return [Hash] The updated solr hash.
      def apply_to(hsh)
        return hsh if values.blank?
        fields.each do |field|
          hsh["#{key}_#{field}".to_sym] ||= []
          hsh["#{key}_#{field}".to_sym] += values
        end
        hsh
      end
    end

    ##
    # Wraps up multiple SolrRows to apply them all at once, while looking like
    # just one.
    class CompositeSolrRow
      attr_reader :solr_rows

      # @param [Array<Valkyrie::Persistence::Solr::Mapper::SolrRow>] solr_rows
      def initialize(solr_rows)
        @solr_rows = solr_rows
      end

      # Merge a Hash of attribute values into a logical row of Solr fields
      # @param [Hash] hsh
      # @see Valkyrie::Persistence::Solr::Mapper::SolrRow#apply_to
      def apply_to(hsh)
        solr_rows.each do |solr_row|
          solr_row.apply_to(hsh)
        end
        hsh
      end
    end

    # Container for casting mappers.
    class SolrMapperValue < ::Valkyrie::ValueMapper
    end

    # Casts {Boolean} values into a recognizable string in Solr.
    class BooleanPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value behaves like a boolean value
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && ([true, false].include? value.value)
      end

      # Constructs a SolrRow object for a Property with a Boolean value
      # @note this prepends the string "boolean-" to the value indexed in Solr
      # @return [SolrRow]
      def result
        calling_mapper.for(Property.new(value.key, "boolean-#{value.value}")).result
      end
    end

    # Casts nested resources into a JSON string in solr.
    class NestedObjectValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is a Hash
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.value.is_a?(Hash) || value.value.is_a?(Valkyrie::Resource)
      end

      # Constructs a SolrRow object for a Property with a Hash value
      # @note this prepends the string "serialized-" to the value indexed in Solr
      # This is indexed as a stored multivalued text
      # @see https://lucene.apache.org/solr/guide/defining-fields.html#defining-fields
      # @see https://github.com/samvera-labs/valkyrie/blob/main/solr/config/schema.xml
      # @return [SolrRow]
      def result
        SolrRow.new(key: value.key, fields: ["tsim"], values: ["serialized-#{value.value.to_json}"])
      end
    end

    # Casts enumerable values one by one.
    class EnumerableValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is an Array
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(Array)
      end

      # Constructs a CompositeSolrRow object for a set of Property values
      # @return [CompositeSolrRow]
      def result
        CompositeSolrRow.new(
          value.value.map do |val|
            calling_mapper.for(Property.new(value.key, val, value.value)).result
          end
        )
      end
    end

    # Casts {Valkyrie::ID} values into a recognizable string in solr.
    class IDPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is a Valkyrie ID
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(::Valkyrie::ID)
      end

      # Constructs a SolrRow object for the Property Valkyrie ID value
      # @note this prepends the string "id-" to the value indexed in Solr
      # @return [SolrRow]
      def result
        calling_mapper.for(Property.new(value.key, "id-#{value.value.id}")).result
      end
    end

    # Casts {RDF::URI} values into a recognizable string in solr.
    class URIPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is a URI
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(::RDF::URI)
      end

      # Constructs a SolrRow object for the Property URI value
      # @note this prepends the string "uri-" to the value indexed in Solr
      # @return [SolrRow]
      def result
        calling_mapper.for(Property.new(value.key, "uri-#{value.value}")).result
      end
    end

    # Casts {Integer} values into a recognizable string in Solr.
    class IntegerPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is an Integer
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(Integer)
      end

      # Constructs a SolrRow object for the Property Integer value
      # @note this prepends the string "integer-" to the value indexed in Solr
      # @return [SolrRow]
      def result
        calling_mapper.for(Property.new(value.key, "integer-#{value.value}")).result
      end
    end

    # Casts {Float} values into a recognizable string in Solr.
    class FloatPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(Float)
      end

      def result
        calling_mapper.for(Property.new(value.key, "float-#{value.value}")).result
      end
    end

    # Casts {DateTime} values into a recognizable string in Solr.
    class DateTimePropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is a DateTime or Time
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && (value.value.is_a?(Time) || value.value.is_a?(DateTime))
      end

      # Constructs a SolrRow object for a datestamp derived from the value
      # @note this prepends the string "datetime-" to the value indexed in Solr
      # @return [SolrRow]
      def result
        calling_mapper.for(Property.new(value.key, "datetime-#{JSON.parse(to_datetime(value.value).to_json)}")).result
      end

      private

      # Converts a value to a UTC timestamp if it is a DateTime or behaves like a Time value
      # @param [Object] value
      # @return [Time]
      def to_datetime(value)
        return value.new_offset(0) if value.is_a?(DateTime)
        return value.to_datetime.new_offset(0) if value.respond_to?(:to_datetime)
      end
    end

    # Handles casting language-tagged strings when there are both
    # language-tagged and non-language-tagged strings in Solr. Assumes English
    # for non-language-tagged strings.
    class SharedStringPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is a String whether or not the Property has an RDF literal specifying the language tag
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(String) && value.scope.find { |x| x.is_a?(::RDF::Literal) }.present?
      end

      # Constructs a CompositeSolrRow object with the language-tagged literal value
      # @return [CompositeSolrRow]
      def result
        CompositeSolrRow.new(
          [
            calling_mapper.for(Property.new(value.key, value.value)).result,
            calling_mapper.for(Property.new("#{value.key}_lang", "eng")).result,
            calling_mapper.for(Property.new("#{value.key}_type", "http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")).result
          ]
        )
      end
    end

    # Handles casting strings.
    class StringPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is a String
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(String)
      end

      # Constructs a SolrRow object with the String values and Solr field settings
      # @return [SolrRow]
      def result
        SolrRow.new(key: value.key, fields: fields, values: [value.value])
      end

      # Generates the Solr fields used during the indexing
      # String are normally indexed using the following:
      #   - stored text
      #   - stored english text
      #   - stored single string
      #   - multivalued string
      #   - stored multivalued text
      #   - stored multivalued english text
      # If the string is greater than 1000 characters in length, it is only indexed as a stored multivalued text
      # @see https://lucene.apache.org/solr/guide/defining-fields.html#defining-fields
      # @see https://github.com/samvera-labs/valkyrie/blob/main/solr/config/schema.xml
      # @return [Array<Symbol>]
      def fields
        if value.value.length > 1000
          [:tsim]
        else
          [:tsim, :ssim, :tesim, :tsi, :ssi, :tesi]
        end
      end
    end

    # Handles casting language-typed {RDF::Literal}s
    class LiteralPropertyValue < ::Valkyrie::ValueMapper
      SolrMapperValue.register(self)

      # Determines whether or not a Property value is an RDF literal
      # @param [Object] value
      # @return [Boolean]
      def self.handles?(value)
        value.is_a?(Property) && value.value.is_a?(::RDF::Literal)
      end

      # Constructs a CompositeSolrRow object with the language-tagged literal value
      # @return [CompositeSolrRow]
      def result
        key = value.key
        val = value.value
        CompositeSolrRow.new(
          [
            calling_mapper.for(Property.new(key, val.to_s)).result,
            calling_mapper.for(Property.new("#{key}_lang", val.language.to_s)).result,
            calling_mapper.for(Property.new("#{key}_type", val.datatype.to_s)).result
          ]
        )
      end
    end
  end
end
