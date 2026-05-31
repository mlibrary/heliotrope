# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  class Persister
    # Responsible for converting {LDP::Container::Basic} to {Valkyrie::Resource}
    class OrmConverter
      attr_reader :object, :adapter
      delegate :graph, to: :object

      # @param [Ldp::Container::Basic] object
      # @param [Valkyrie::Persistence::Fedora::MetadataAdapter] adapter
      def initialize(object:, adapter:)
        @object = object
        @adapter = adapter
      end

      # Convert a Fedora LDP container to a Valkyrie Resource
      # @return [Valkyrie::Resource]
      def convert
        populate_native_lock(Valkyrie::Types::Anything[attributes])
      end

      # Generate a Hash resulting from the mapping of Fedora LDP graphs to Valkyrie Resource attributes
      # For example:
      #   {
      #     :internal_resource => "CustomResource",
      #     :created_at => 2018-08-08 15:45:03 UTC,
      #     [...]
      #     id => #<Valkyrie::ID:0x00007ff821e9cb38 @id="9e5aef75-f4cc-42f4-b050-0eadeeab908d",
      #     new_record => false
      #   }
      # @return [Hash]
      def attributes
        GraphToAttributes.new(graph: graph, adapter: adapter)
                         .convert
                         .merge(id: id, new_record: false)
      end

      # Get Fedora's lastModified value from the LDP response
      def populate_native_lock(resource)
        return resource unless resource.respond_to?(Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK)
        lastmod = object.response_graph.first_object([nil, RDF::URI("http://fedora.info/definitions/v4/repository#lastModified"), nil])
        return resource unless lastmod

        token = Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: "native-#{adapter.id}", token: DateTime.parse(lastmod.to_s).httpdate)
        resource.send(Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK) << token
        resource
      end

      # Generate the Valkyrie ID from the existing Fedora LDP resource property
      # Should no such property exist, the URI for the LDP resource is used to mint a new one
      # @return [Valkyrie::ID]
      def id
        id_property.present? ? Valkyrie::ID.new(id_property) : adapter.uri_to_id(object.subject_uri)
      end

      # Retrieve the RDF property for the Valkyrie ID
      # @see {Valkyrie::Persistence::Fedora::Persister::ModelConverter::NestedInternalValkyrieID}
      # @return [String]
      def id_property
        return unless object.subject_uri.to_s.include?("#")
        object.graph.query([RDF::URI(""), PermissiveSchema.id, nil]).to_a.first.try(:object).to_s
      end

      # Class for deriving an attribute Hash from a Fedora LDP resource graph
      class GraphToAttributes
        attr_reader :graph, :adapter

        # @param [RDF::Graph] graph
        # @param [Valkyrie::Persistence::Fedora::MetadataAdapter] adapter
        def initialize(graph:, adapter:)
          @graph = graph
          @adapter = adapter
        end

        # Generates FedoraValue objects for each statement in the Fedora LDP resource graph
        #   Using these objects, it then generates a Hash of Valkyrie Resource attributes
        # @return [Hash]
        def convert
          graph.each do |statement|
            FedoraValue.for(Property.new(statement: statement, scope: graph, adapter: adapter)).result.apply_to(attributes)
          end
          attributes
        end

        # Access the attributes populated by RDF graph statements
        # @return [Hash]
        def attributes
          @attributes ||= {}
        end

        # Class mapping values
        class FedoraValue < ::Valkyrie::ValueMapper
          # Constructs an Applicator object for the value being mapped
          # @return [Applicator]
          def result
            Applicator.new(value)
          end
        end

        # Class for handling cases where deny listed values should not be mapped
        class DenylistedValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)
          # Determines whether or not the value has a denied namespace for the RDF statement object
          # (i. e. avoid attempting to map any RDF statements making assertions about LDP containers or resource internal to Fedora)
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.to_s.start_with?("http://www.w3.org/ns/ldp", "http://fedora.info")
          end

          # Provide the NullApplicator Class for any Property in a deny listed namespace
          def result
            NullApplicator
          end
        end

        # Class for handling cases where the RDF subject of a Property references a separate resource using a hash URI
        class DifferentSubject < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not the value has an RDF subject using a hash URI
          #   (Hash URIs are treated as different resources)
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.subject.to_s.include?("#")
          end

          # Provide the NullApplicator Class for any Property with a hash URI in the RDF subject
          def result
            NullApplicator
          end
        end

        # Class for handling Arrays of Properties
        class CompositeApplicator
          attr_reader :applicators

          # @param [Array<Applicator>] applicators
          def initialize(applicators)
            @applicators = applicators
          end

          # Enumerate through the Applicator constructed for each Property
          #   updating the Valkyrie resource attribute Hash with each result
          # @param [Hash] hsh a new or existing Hash of attribute for Valkyrie resource attributes
          # @return [Hash]
          def apply_to(hsh)
            applicators.each do |applicator|
              applicator.apply_to(hsh)
            end
            hsh
          end
        end

        # Class for mapping resource member IDs in an RDF linked list
        class MemberID < ::Valkyrie::ValueMapper
          delegate :scope, :adapter, to: :value
          FedoraValue.register(self)

          # Determines whether or not the Property statement references an RDF linked list
          # @param [Property] value
          def self.handles?(value)
            value.statement.predicate == ::RDF::Vocab::IANA.first
          end

          # Constructs a CompositeApplicator object for each element in the RDF linked list
          # Involves mapping to Property objects using an OrderedList
          # @return [CompositeApplicator]
          def result
            value.statement.predicate = PermissiveSchema.member_ids
            values = OrderedList.new(scope, head, tail, adapter).to_a.map(&:proxy_for)
            values = values.map do |val|
              calling_mapper.for(Property.new(statement: RDF::Statement.new(value.statement.subject, value.statement.predicate, val), scope: value.scope, adapter: value.adapter)).result
            end
            CompositeApplicator.new(values)
          end

          # Retrieve the URI for the first element in the linked list
          # @return [RDF::URI]
          def head
            scope.query([value.statement.subject, RDF::Vocab::IANA.first]).to_a.first.object
          end

          # Retrieve the URI for the last element in the linked list
          # @return [RDF::URI]
          def tail
            scope.query([value.statement.subject, RDF::Vocab::IANA.last]).to_a.first.object
          end
        end

        class OrderedProperty < ::Valkyrie::ValueMapper
          delegate :scope, :adapter, to: :value
          FedoraValue.register(self)
          def self.handles?(value)
            value.statement.object.is_a?(RDF::URI) && value.statement.object.to_s.include?("#") &&
              (value.statement.object.to_s.start_with?("#") ||
               value.statement.object.to_s.start_with?(value.adapter.connection_prefix)) &&
              value.scope.query([value.statement.object, nil, nil]).map(&:predicate).include?(::RDF::Vocab::IANA.first)
          end

          def result
            values = OrderedList.new(scope, head, tail, adapter).to_a.map(&:proxy_for)
            values = values.map do |val|
              calling_mapper.for(Property.new(statement: RDF::Statement.new(value.statement.subject, value.statement.predicate, val), scope: value.scope, adapter: value.adapter)).result
            end
            CompositeApplicator.new(values)
          end

          def head
            scope.query([value.statement.object, RDF::Vocab::IANA.first]).to_a.first.object
          end

          def tail
            scope.query([value.statement.object, RDF::Vocab::IANA.last]).to_a.first.object
          end
        end

        # Class for mapping RDF child graphs within parent graphs
        class NestedValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property lies within a parent graph
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::URI) && value.statement.object.to_s.include?("#") &&
              (value.statement.object.to_s.start_with?("#") ||
               value.statement.object.to_s.start_with?(value.adapter.connection_prefix))
          end

          # Construct an Applicator object from the parent graph for the child graph in this Property
          # @return [Applicator]
          def result
            value.scope.each do |statement|
              next unless statement.subject.to_s.include?("#")
              subject = new_subject(statement)
              graph << RDF::Statement.new(subject, statement.predicate, statement.object)
            end
            value.statement.object = resource
            Applicator.new(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter))
          end

          # Construct a new GraphContainer object for the parent graph of the child graph in this Property
          # @return [GraphContainer]
          def container
            GraphContainer.new(graph, value.statement.object)
          end

          # Recursively convert the parent graph into a Valkyrie Resource
          # @return [Valkyrie::Resource]
          def resource
            OrmConverter.new(object: container, adapter: value.adapter).convert
          end

          # Retrieve a new RDF subject for a given statement
          #   If the subject of the statement and that of the Property statement are the same, generate an empty URI
          # @param [RDF::Statement] statement
          # @return [RDF::URI]
          def new_subject(statement)
            if statement.subject == value.statement.object
              RDF::URI("")
            else
              statement.subject
            end
          end

          # Construct the RDF graph used for the parent graph
          # @return [RDF::Graph]
          def graph
            @graph ||= RDF::Graph.new
          end

          # Models a container for parent graphs
          class GraphContainer
            attr_reader :graph, :subject_uri

            # @param [RDF::Graph] graph
            # @param [RDF::URI] subject_uri
            def initialize(graph, subject_uri)
              @graph = graph
              @subject_uri = subject_uri
            end
          end
        end

        # Class for mapping RDF boolean literals into Valkyrie Resource attribute values
        class BooleanValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is an RDF literal typed for boolean values
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.language.blank? && value.statement.object.datatype == PermissiveSchema.valkyrie_bool
          end

          # Casts the value of the RDF literal into an Applicator for Boolean values
          # @return [Applicator]
          def result
            value.statement.object = value.statement.object.value.casecmp("true").zero?
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Class for mapping RDF datetime literals into Valkyrie Resource attribute values
        class DateTimeValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is an RDF literal typed for datetime values
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.language.blank? && value.statement.object.datatype == PermissiveSchema.valkyrie_datetime
          end

          # Casts the value of the RDF literal into an Applicator for DateTime values
          # @return [Applicator]
          def result
            value.statement.object = ::DateTime.iso8601(value.statement.object.to_s).new_offset(0)
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Class for mapping RDF integer literals into Valkyrie Resource attribute values
        class IntegerValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is an RDF literal typed for Integer values
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.language.blank? && value.statement.object.datatype == PermissiveSchema.valkyrie_int
          end

          # Casts the value of the RDF literal into an Applicator for Integer values
          # @return [Applicator]
          def result
            value.statement.object = value.statement.object.value.to_i
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        class FloatValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.language.blank? && value.statement.object.datatype == PermissiveSchema.valkyrie_float
          end

          def result
            value.statement.object = value.statement.object.value.to_f
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Class for mapping RDF XML literals into Valkyrie Resource attribute values
        class LiteralValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is an RDF literal typed using XML data types
          # @see https://www.w3.org/TR/rdf11-concepts/#section-Graph-Literal
          # @see https://www.w3.org/TR/xmlschema-2/#built-in-datatypes
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.language.blank? && value.statement.object.datatype == RDF::URI("http://www.w3.org/2001/XMLSchema#string")
          end

          # Casts the value of the RDF literal into an Applicator for XML datatype values
          # @return [Applicator]
          def result
            value.statement.object = value.statement.object.to_s
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Class for mapping RDF datetime literals into Valkyrie Resource attribute values
        # Class for mapping Property objects for Time values
        # Technically Valkyrie does not support time, but when other persisters support time
        #  this code will make Fedora compliant with the established patterns.
        #
        #  https://github.com/samvera-labs/valkyrie/wiki/Supported-Data-Types
        class TimeValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is an RDF literal typed for Time values
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.language.blank? && value.statement.object.datatype == PermissiveSchema.valkyrie_time
          end

          # Casts the value of the RDF literal into an Applicator for DateTime values
          # @return [Applicator]
          def result
            value.statement.object = DateTime.parse(value.statement.object.to_s).new_offset(0)
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Casts the value of the RDF literal into an Applicator for Valkyrie ID objects
        # @return [Applicator]
        class ValkyrieIDValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is an RDF literal typed for Valkyrie ID literals
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::Literal) && value.statement.object.datatype == PermissiveSchema.valkyrie_id
          end

          # Casts the value of the RDF literal into an Applicator for Valkyrie::ID objects
          # @return [Applicator]
          def result
            value.statement.object = Valkyrie::ID.new(value.statement.object.to_s)
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Casts the value of the RDF literal into an Applicator for URIs referencing Valkyrie Resources
        # @return [Applicator]
        class InternalURI < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not a Property statement is URI referring internally to a Valkyrie Resource
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.object.is_a?(RDF::URI) && value.statement.object.to_s.start_with?(value.adapter.connection_prefix)
          end

          # Casts the value of the URI into an Applicator for Valkyrie::Resource objects
          # @return [Applicator]
          def result
            value.statement.object = value.adapter.uri_to_id(value.statement.object)
            calling_mapper.for(Property.new(statement: value.statement, scope: value.scope, adapter: value.adapter)).result
          end
        end

        # Casts the value of the RDF statements encoding the type of Valkyrie Resource into the resource type
        # @return [Applicator]
        class InternalModelValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not the Property RDF statement refers to a resource type
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.predicate == value.adapter.schema.predicate_for(property: :internal_resource, resource: nil)
          end

          # Constructs a SingleApplicator object for mapping the resource type
          # @return [SingleApplicator]
          def result
            SingleApplicator.new(value)
          end
        end

        # Casts the value of the RDF statements encoding the time of creation for the Valkyrie Resource into a DateTime value
        # @return [Applicator]
        class CreatedAtValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not the Property RDF statement encodes a creation date
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.predicate == value.adapter.schema.predicate_for(property: :created_at, resource: nil)
          end

          # Constructs a NonStringSingleApplicator object for mapping the resource creation time
          # @return [NonStringSingleApplicator]
          def result
            NonStringSingleApplicator.new(value)
          end
        end

        # Casts the value of the RDF statements encoding the time of last update creation for the Valkyrie Resource into a DateTime value
        # @return [Applicator]
        class UpdatedAtValue < ::Valkyrie::ValueMapper
          FedoraValue.register(self)

          # Determines whether or not the Property RDF statement encodes an update date
          # @param [Property] value
          # @return [Boolean]
          def self.handles?(value)
            value.statement.predicate == value.adapter.schema.predicate_for(property: :updated_at, resource: nil)
          end

          # Constructs a NonStringSingleApplicator object for mapping the time at which the resource was last updated
          # @return [NonStringSingleApplicator]
          def result
            NonStringSingleApplicator.new(value)
          end
        end

        # Class for mapping nil values to the Valkyrie attribute Hash
        class NullApplicator
          # No nil object is actually added (this is a no-op)
          # @param [Hash] hsh a new or existing Hash of attribute for Valkyrie resource attributes
          # @param [Hash]
          def self.apply_to(_hsh); end
        end

        # Class for mapping RDF statements in Property objects to Valkyrie Resource attributes
        class Applicator
          attr_reader :property
          delegate :statement, :adapter, to: :property
          delegate :schema, to: :adapter

          # @param [Property] property
          def initialize(property)
            @property = property
          end

          # Apply as a single value by default, if there are multiple then
          # create an array. Done to support single values - if the resource is
          # a Set or Array then it'll cast the single value back to an array
          # appropriately.
          # @param [Hash] hsh a new or existing Hash of attribute for Valkyrie resource attributes
          # @return [Hash]
          def apply_to(hsh)
            return if deny?(key)
            hsh[key.to_sym] = if hsh.key?(key.to_sym)
                                Array.wrap(hsh[key.to_sym]) + cast_array(values)
                              else
                                values
                              end
          end

          # Derive the key for the Valkyrie resource attribute from the RDF statement in the Property
          # @return [Symbol]
          def key
            predicate = statement.predicate.to_s
            key = schema.property_for(resource: nil, predicate: predicate)
            namespaces.each do |namespace|
              key = key.to_s.gsub(/^#{namespace}/, '')
            end
            key
          end

          # Determines whether or not a key is on the deny list for mapping
          # (For example <http://fedora.info/definitions> assertions are not mapped to Valkyrie attributes)
          # @param [Symbol] key
          # @return [Boolean]
          def deny?(key)
            denylist.each do |denylist_item|
              return true if key.start_with?(denylist_item)
            end
            false
          end

          # Casts values into an Array
          # @param [Object] values
          # @return [Array<Object>]
          def cast_array(values)
            Array(values)
          end

          # Retrieve a list of denied URIs for predicates
          # @return [Array<String>]
          def denylist
            [
              "http://fedora.info/definitions",
              "http://www.iana.org/assignments/relation/last"
            ]
          end

          # Retrieve a list of namespace URIs for predicates
          # @return [Array<String>]
          def namespaces
            [
              "http://www.fedora.info/definitions/v4/",
              "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            ]
          end

          # Access the object for the RDF statement
          # @return [RDF::URI]
          def values
            statement.object
          end
        end

        # Class for mapping single values
        class SingleApplicator < Applicator
          # Ensure that the value string is inserted into the attribute Hash
          # @param [Hash] hsh a new or existing Hash of attribute for Valkyrie resource attributes
          # @return [Hash]
          def apply_to(hsh)
            hsh[key.to_sym] = values.to_s
          end
        end

        # Class for mapping single values other than Strings
        class NonStringSingleApplicator < Applicator
          # For the trivial case, insert the value into the attribute Hash
          # @param [Hash] hsh a new or existing Hash of attribute for Valkyrie resource attributes
          # @return [Hash]
          def apply_to(hsh)
            hsh[key.to_sym] = values
          end
        end

        # Class modeling RDF statements for Fedora LDP resources
        class Property
          attr_reader :statement, :scope, :adapter

          # @param [RDF::Statement] statement
          # @param [RDF::Graph] scope
          # @param [Valkyrie::Persistence::Fedora::MetadataAdapter] adapter
          def initialize(statement:, scope:, adapter:)
            @statement = statement
            @scope = scope
            @adapter = adapter
          end
        end
      end
    end
  end
end
