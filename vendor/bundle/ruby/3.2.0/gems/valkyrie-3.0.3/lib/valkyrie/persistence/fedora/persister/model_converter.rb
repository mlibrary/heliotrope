# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  class Persister
    # Responsible for converting {Valkyrie::Resource} to {LDP::Container::Basic}
    class ModelConverter
      attr_reader :resource, :adapter, :subject_uri
      delegate :connection, :connection_prefix, :base_path, to: :adapter

      # @param [Valkyrie::Resource] resource
      # @param [Valkyrie::Persistence::Fedora::MetadataAdapter] adapter
      # @param [RDF::URI] subject_uri
      def initialize(resource:, adapter:, subject_uri: RDF::URI(""))
        @resource = resource
        @adapter = adapter
        @subject_uri = subject_uri
      end

      # Convert a Valkyrie Resource into a RDF LDP basic container
      # @return [Ldp::Container::Basic]
      def convert
        graph_resource.graph.delete([nil, nil, nil])
        properties.each do |property|
          values = resource_attributes[property]

          output = property_converter.for(Property.new(subject_uri, property, values, adapter, resource)).result
          graph_resource.graph << output.to_graph
        end
        graph_resource
      end

      # Access the Valkyrie attribute names to be used for the Fedora resource properties
      # Filters resource properties to remove properties that should not be persisted to Fedora.
      # * new_record is a virtual property for marking unsaved objects
      # @return [Array<Symbol>]
      def properties
        resource_attributes.keys - [:new_record]
      end

      delegate :attributes, to: :resource, prefix: true

      # Construct the LDP Basic Container modeling the Valkyrie Resource in Fedora
      # @see https://www.w3.org/TR/ldp/#ldpc
      # @return [Ldp::Container::Basic]
      def graph_resource
        @graph_resource ||= ::Ldp::Container::Basic.new(connection, subject, nil, base_path)
      end

      # Generate a URI from the Valkyrie Resource ID to be used as the RDF subject for Fedora LDP resources
      # @return [RDF::URI]
      def subject
        adapter.id_to_uri(resource.id) if resource.try(:id)
      end

      # Provide the Class used for values
      # This should be derived from Valkyrie::ValueMapper as a base class
      # @return [Class]
      def property_converter
        FedoraValue
      end

      # Class modeling properties for Fedora LDP resources
      # These map directly to attributes on the Valkyrie resources and generate a new graph or populate an existing graph
      class Property
        attr_reader :key, :value, :subject, :adapter, :resource
        delegate :schema, to: :adapter

        # @param [RDF::URI] subject RDF URI referencing the LDP container in the graph store
        # @param [Symbol] key attribute key used to map to the RDF predicate
        # @param [Object] value
        # @param [Valkyrie::Persistence::Fedora::MetadataAdapter] adapter
        # @param [Valkyrie::Resource] resource
        def initialize(subject, key, value, adapter, resource)
          @subject = subject
          @key = key
          @value = value
          @adapter = adapter
          @resource = resource
        end

        # Populate the RDF graph containing statements about the LDP container
        # @param [RDF::Graph] graph
        # @return [RDF::Graph]
        def to_graph(graph = RDF::Graph.new)
          Array(value).each do |val|
            graph << RDF::Statement.new(subject, predicate, val)
          end
          graph
        end

        # Retrieve the RDF predicate for this Valkyrie Resource attribute (being converted)
        # This is used to generate RDF statements (triples) from Resource attributes
        # @return [RDF::URI]
        def predicate
          schema.predicate_for(resource: resource, property: key)
        end
      end

      # Class modeling RDF properties which are sets of graphs
      # (i. e. this generates a parent graph from a set of child graphs)
      class CompositeProperty
        attr_reader :properties

        # @param [Array<Property>] properties
        def initialize(properties)
          @properties = properties
        end

        # Generate the RDF graph
        # @param [RDF::Graph] graph RDF graph being populated with "member" graphs
        # @return [RDF::Graph] the populated "parent" graph
        def to_graph(graph = RDF::Graph.new)
          properties.each do |property|
            property.to_graph(graph)
          end
          graph
        end
      end

      # Class modeling RDF properties which are single, existing graphs
      # (i. e. this inserts a single existing "child" graph into a "parent" graph)
      class GraphProperty
        attr_reader :key, :graph, :subject, :adapter, :resource

        # @param [RDF::URI] subject RDF URI referencing the LDP container in the graph store
        # @param [Symbol] key attribute key used to map to the RDF predicate
        # @param [RDF::Graph] graph RDF graph for the existing property
        # @param [Valkyrie::Persistence::Fedora::MetadataAdapter] adapter
        # @param [Valkyrie::Resource] resource
        def initialize(subject, key, graph, adapter, resource)
          @subject = subject
          @key = key
          @graph = graph
          @adapter = adapter
          @resource = resource
        end

        # Appends the existing graph to a new or existing "parent" graph
        # @param [RDF::Graph] passed_graph
        # @return [RDF::Graph] the updated "parent" graph
        def to_graph(passed_graph = RDF::Graph.new)
          passed_graph << graph
        end
      end

      # (Abstract) base class for Fedora property values
      class FedoraValue < ::Valkyrie::ValueMapper
      end

      # Class mapping Fedora property values which must be ordered
      # This assumes that the value being mapped is actually an Array (or Enumerable)
      class OrderedMembers < ::Valkyrie::ValueMapper
        FedoraValue.register(self)

        # Determines whether or not the Valkyrie attribute value can be ordered
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.key == :member_ids && Array(value.value).present?
        end

        # Construct a graph from the value array
        # @return [GraphProperty]
        def result
          initialize_list
          apply_first_and_last
          GraphProperty.new(value.subject, value.key, graph, value.adapter, value.resource)
        end

        # Generate the RDF Graph from from the ordered value array
        # @return [RDF::Graph]
        def graph
          @graph ||= ordered_list.to_graph
        end

        # Append the RDF statements asserting that two RDF resources are the "first" and "last" elements of the linked list
        # @return [RDF::Graph]
        def apply_first_and_last
          return if ordered_list.to_a.empty?
          graph << RDF::Statement.new(value.subject, ::RDF::Vocab::IANA.first, ordered_list.head.next.rdf_subject)
          graph << RDF::Statement.new(value.subject, ::RDF::Vocab::IANA.last, ordered_list.tail.prev.rdf_subject)
        end

        # Populate an OrderedList object (wrapping an RDF graph implementation of a linked list) using the value array
        def initialize_list
          Array(value.value).each_with_index do |val, index|
            ordered_list.insert_proxy_for_at(index, calling_mapper.for(Property.new(value.subject, :member_id, val, value.adapter, value.resource)).result.value)
          end
        end

        # Construct an OrderedList object
        # @return [OrderedList]
        def ordered_list
          @ordered_list ||= OrderedList.new(RDF::Graph.new, nil, nil, value.adapter)
        end
      end

      class OrderedProperties < ::Valkyrie::ValueMapper
        FedoraValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && ordered?(value) && !OrderedMembers.handles?(value) && Array(value.value).present? && value.value.is_a?(Array)
        end

        def self.ordered?(value)
          return false unless value.resource.class.attribute_names.include?(value.key)
          value.resource.ordered_attribute?(value.key)
        end

        delegate :subject, to: :value

        def result
          initialize_list
          apply_first_and_last
          GraphProperty.new(value.subject, value.key, graph, value.adapter, value.resource)
        end

        def graph
          @graph ||= ordered_list.to_graph
        end

        def apply_first_and_last
          return if ordered_list.to_a.empty?
          graph << RDF::Statement.new(subject, predicate, node_id)
          graph << RDF::Statement.new(node_id, ::RDF::Vocab::IANA.first, ordered_list.head.next.rdf_subject)
          graph << RDF::Statement.new(node_id, ::RDF::Vocab::IANA.last, ordered_list.tail.prev.rdf_subject)
        end

        def node_id
          @node_id ||= ordered_list.send(:new_node_subject)
        end

        def predicate
          value.schema.predicate_for(resource: value.resource, property: value.key)
        end

        def initialize_list
          Array(value.value).each_with_index do |val, index|
            property = NestedProperty.new(value: val, scope: value)
            obj = calling_mapper.for(property.property).result
            # Append value directly if possible.
            if obj.respond_to?(:value)
              ordered_list.insert_proxy_for_at(index, proxy_for_value(obj.value))
            # If value is a nested object, take its graph and append it.
            elsif obj.respond_to?(:graph)
              append_to_graph(obj: obj, index: index, property: property.property)
            end
            graph << ordered_list.to_graph
          end
        end

        def proxy_for_value(value)
          if value.is_a?(RDF::Literal) && value.datatype == PermissiveSchema.valkyrie_id
            ordered_list.adapter.id_to_uri(value)
          else
            value
          end
        end

        class NestedProperty
          attr_reader :value, :scope
          def initialize(value:, scope:)
            @value = value
            @scope = scope
          end

          def property
            @property ||= Property.new(node, key, value, scope.adapter, scope.resource)
          end

          def key
            scope.key.to_s.singularize.to_sym
          end

          def node
            @node ||= ::RDF::URI("##{::RDF::Node.new.id}")
          end
        end

        def append_to_graph(obj:, index:, property:)
          proxy_node = obj.graph.query([nil, property.predicate, nil]).objects[0]
          obj.graph.delete([nil, property.predicate, nil])
          ordered_list.insert_proxy_for_at(index, proxy_node)
          obj.to_graph(graph)
        end

        def ordered_list
          @ordered_list ||= OrderedList.new(RDF::Graph.new, nil, nil, value.adapter)
        end
      end

      # Class mapping Valkyrie attribute values which have already been
      #   mapped to Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property objects
      class NestedProperty < ::Valkyrie::ValueMapper
        FedoraValue.register(self)

        # Determines whether or not the Valkyrie attribute value can be ordered
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && (value.value.is_a?(Hash) || value.value.is_a?(Valkyrie::Resource)) && value.value[:internal_resource]
        end

        # Generate a new parent graph containing the child graph generated from the ModelConverter::Property objects
        # @return [GraphProperty]
        def result
          nested_graph << RDF::Statement.new(value.subject, value.predicate, subject_uri)
          GraphProperty.new(value.subject, value.key, nested_graph, value.adapter, value.resource)
        end

        # Generate the "child" graph from the value in the ModelConverter::Property
        # @return [RDF::Graph]
        def nested_graph
          @nested_graph ||= ModelConverter.new(resource: Valkyrie::Types::Anything[value.value], adapter: value.adapter, subject_uri: subject_uri).convert.graph
        end

        # Generate a new RDF hash URI for the "child" graph for the ModelConverter::Property
        # @return [RDF::Graph]
        def subject_uri
          @subject_uri ||= ::RDF::URI(RDF::Node.new.to_s.gsub("_:", "#"))
        end
      end

      # Class used to map values converted into default Ruby data types (e. g. Strings)
      #   into Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property objects
      class MappedFedoraValue < ::Valkyrie::ValueMapper
        private

        # Map a default Ruby data type
        # (This maps the existing Property to a FedoraValue first)
        # @param [Object] converted_value
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def map_value(converted_value:)
          calling_mapper.for(
            Property.new(
              value.subject,
              value.key,
              converted_value,
              value.adapter,
              value.resource
            )
          ).result
        end
      end

      # Class mapping Property objects for Valkyrie IDs using typed RDF literals
      # This generates a custom datatype URI for Valkyrie IDs
      # @see https://www.w3.org/TR/rdf11-concepts/#section-Graph-Literal
      # @see https://www.w3.org/TR/rdf11-concepts/#datatype-iris
      class NestedInternalValkyrieID < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for Valkyrie ID with a hash URI for the RDF graph
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Valkyrie::ID) && value.subject.to_s.include?("#")
        end

        # Converts the RDF literal into the Property
        # For example, a Valkyrie::ID with the value "db67d786-d187-46b8-a44f-a494f0c65ec2"
        #   will first be mapped to RDF::Literal "db67d786-d187-46b8-a44f-a494f0c65ec2"^^<http://example.com/predicate/valkyrie_id>
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          map_value(converted_value: RDF::Literal.new(
            value.value,
            datatype: PermissiveSchema.valkyrie_id
          ))
        end
      end

      # Class mapping Property objects for Valkyrie IDs which have not been mapped to Fedora LDP URIs
      class InternalValkyrieID < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for Valkyrie ID which is not contain an adapter resource path URI
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Valkyrie::ID) && !value.value.to_s.include?("://")
        end

        # Generates the Property for this URI
        # For example, a Valkyrie::ID with the value "c0831f2e-f86b-4d4a-9331-020b7418b068"
        #   will first be mapped to <http://localhost:8988/rest/test_fed/c0/83/1f/2e/c0831f2e-f86b-4d4a-9331-020b7418b068>
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          map_value(converted_value: value.adapter.id_to_uri(value.value))
        end
      end

      # Class for mapping Property objects for Boolean values
      class BooleanValue < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for boolean values
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && ([true, false].include? value.value)
        end

        # Generates the Property for this boolean
        # RDF::Literal::Boolean:0x3fc310fdf120("false"^^<http://example.com/predicate/valkyrie_bool>)
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          map_value(converted_value: RDF::Literal.new(
            value.value,
            datatype: PermissiveSchema.valkyrie_bool
          ))
        end
      end

      # Class for mapping Property objects for Integer values
      class IntegerValue < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for Integer values
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Integer)
        end

        # Generates the Property for this Integer
        # #<RDF::Literal::Integer:0x3fc8a104f570("1"^^<http://example.com/predicate/valkyrie_int>)>
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          map_value(converted_value: RDF::Literal.new(
            value.value,
            datatype: PermissiveSchema.valkyrie_int
          ))
        end
      end

      class FloatValue < MappedFedoraValue
        FedoraValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Float)
        end

        def result
          map_value(converted_value: RDF::Literal.new(
            value.value,
            datatype: PermissiveSchema.valkyrie_float
          ))
        end
      end

      # Class for mapping Property objects for DateTime values
      class DateTimeValue < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for DateTime values
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(DateTime)
        end

        # Generates the Property for this DateTime
        # This will first be mapped to an RDF::Literal::DateTime object such as "2018-08-08T11:24:18.2087-04:00"^^<http://example.com/predicate/valkyrie_datetime>
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          map_value(converted_value: RDF::Literal.new(
            value.value,
            datatype: PermissiveSchema.valkyrie_datetime
          ))
        end
      end

      # Class for mapping Property objects for Time values
      # Technically Valkyrie does not support time, but when other persisters support time
      #  this code will make Fedora compliant with the established patterns.
      #
      #  https://github.com/samvera-labs/valkyrie/wiki/Supported-Data-Types
      class TimeValue < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for Time values
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Time)
        end

        # Generates the Property for this Time
        # This will first be mapped to an RDF::Literal::DateTime object such as "2018-08-08T11:24:18.2087-04:00"^^<http://example.com/predicate/valkyrie_datetime>
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          # cast it to datetime for storage, to preserve milliseconds and date
          map_value(converted_value:
              RDF::Literal.new(
                value.value.to_datetime,
                datatype: PermissiveSchema.valkyrie_time
              ))
        end
      end

      # Class for mapping Property objects for simple Valkyrie IDs
      class IdentifiableValue < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for Valkyrie::ID values
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Valkyrie::ID)
        end

        # Converts the RDF literal into the Property
        # For example, a Valkyrie::ID with the value "adapter://1"
        #   will first be mapped to RDF::Literal "adapter://1"^^<http://example.com/predicate/valkyrie_id>
        # @return [Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property]
        def result
          map_value(converted_value: RDF::Literal.new(
            value.value,
            datatype: PermissiveSchema.valkyrie_id
          ))
        end
      end

      # Class mapping Property objects for value arrays
      class EnumerableValue < MappedFedoraValue
        FedoraValue.register(self)

        # Determines whether or not the value is a Property for Array values
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Array)
        end

        # Construct a CompositeProperty composed of the mapped Array elements
        # @return [CompositeProperty]
        def result
          new_values = value.value.map do |val|
            map_value(converted_value: val)
          end
          CompositeProperty.new(new_values)
        end
      end
    end
  end
end
