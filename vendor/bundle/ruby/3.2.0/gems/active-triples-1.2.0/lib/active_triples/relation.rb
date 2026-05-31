# frozen_string_literal: true
require 'active_support/core_ext/module/delegation'

module ActiveTriples
  ##
  # A `Relation` represents the values of a specific property/predicate on an
  # `RDFSource`. Each relation is a set (`Enumerable` of the `RDF::Term`s that 
  # are objects in the of source's triples of the form:
  #
  #     <{#parent}> <{#predicate}> [term] .
  #
  # Relations express a binary relationships (over a predicate) between the 
  # parent node and a set of terms.
  #
  # When the term is a URI or Blank Node, it is represented in the results as an
  # `RDFSource`. Literal values are cast to strings, Ruby native types, or 
  # remain as an `RDF::Literal` as documented in `#each`.
  #
  # @see RDF::Term
  class Relation
    include Enumerable
    include Comparable

    TYPE_PROPERTY = { predicate: RDF.type, cast: false }.freeze

    # @!attribute [rw] parent
    #   @return [RDFSource] the resource that is the domain of this relation
    # @!attribute [rw] value_arguments
    #   @return [Array<Object>]
    # @!attribute [r] rel_args
    #   @return [Hash]
    # @!attribute [r] reflections
    #   @return [Class]
    attr_accessor :parent, :value_arguments
    attr_reader :reflections, :rel_args

    delegate :[], :inspect, :last, :size, :join, to: :to_a

    ##
    # @param [ActiveTriples::RDFSource] parent_source
    # @param [Array<Symbol, Hash>] value_arguments  if a Hash is passed as the
    #   final element, it is removed and set to `@rel_args`.
    def initialize(parent_source, value_arguments)
      self.parent = parent_source
      @reflections = parent_source.reflections
      @rel_args ||= {}
      @rel_args = value_arguments.pop if
        value_arguments.is_a?(Array) && value_arguments.last.is_a?(Hash)

      @value_arguments = value_arguments
    end

    ##
    # @param array [#to_ary, ActiveTriples::Relation]
    # @return [Array]
    #
    # @note simply passes to `Array#&` unless argument is a `Relation`
    #
    # @see Array#&
    def &(array)
      return to_a & array unless array.is_a? Relation

      (objects.to_a & array.objects.to_a)
        .map { |object| convert_object(object) }
    end
    
    ##
    # @param array [#to_ary, ActiveTriples::Relation]
    # @return [Array]
    #
    # @note simply passes to `Array#|` unless argument is a `Relation`
    #
    # @see Array#|
    def |(array)
      return to_a | array unless array.is_a? Relation
      
      (objects.to_a | array.objects.to_a)
        .map { |object| convert_object(object) }
    end

    ##
    # @param array [#to_ary, ActiveTriples::Relation]
    # @return [Array]
    #
    # @note simply passes to `Array#+` unless argument is a `Relation`
    #
    # @see Array#+
    def +(array)
      return to_a + array unless array.is_a? Relation

      (objects.to_a + array.objects.to_a)
        .map { |object| convert_object(object) }
    end

    ##
    # Mimics `Set#<=>`, returning `0` when set membership is equivalent, and 
    # `nil` (as non-comparable) otherwise. Unlike `Set#<=>`, uses `#==` for 
    # member comparisons.
    #
    # @param [Object] other
    #
    # @see Set#<=>
    def <=>(other)
      return nil unless other.respond_to?(:each)

      # If we're empty, avoid calling `#to_a` on other.
      if empty?
        return 0 if other.each.first.nil?
        return nil
      end

      # We'll need to traverse `other` repeatedly, so we get a stable `Array`
      # representation. This avoids any repeated query cost if `other` is a
      # `Relation`.
      length       = 0
      other        = other.to_a
      other_length = other.length
      this         = each

      loop do
        begin
          current = this.next
        rescue StopIteration
          # If we die, we are equal to other so far, check length and walk away.
          return other_length == length ? 0 : nil
        end

        length += 1
        
        # Return as not comparable if we have seen more terms than are in other,
        # or if other does not include the current term.
        return nil if other_length < length || !other.include?(current)
      end
    end

    ##
    # Adds values to the result set
    #
    # @param values [Object, Array<Object>] values to add
    #
    # @return [Relation] a relation containing the set values; i.e. `self`
    def <<(values)
      values = prepare_relation(values) if values.is_a?(Relation)
      self.set(objects.to_a | Array.wrap(values))
    end
    alias_method :push, :<<

    ##
    # Builds a node with the given attributes, adding it to the relation.
    #
    # @param attributes [Hash] a hash of attribute names and values for the
    #   built node.
    #
    # @example building an empty generic node
    #   resource = ActiveTriples::Resource.new
    #   resource.resource.get_values(RDF::Vocab::DC.relation).build
    #   # => #<ActiveTriples::Resource:0x2b0(#<ActiveTriples::Resource:0x005>)>)
    #
    #   resource.dump :ttl
    #   # => "\n [ <http://purl.org/dc/terms/relation> []] .\n"
    #
    # Nodes are built using the configured `class_name` for the relation.
    # Attributes passed in the Hash argument are set on the new node through
    # `RDFSource#attributes=`. If the attribute keys are not valid properties
    # on the built node, we raise an error.
    #
    # @example building a node with attributes
    #   class WithRelation
    #     include ActiveTriples::RDFSource
    #     property :relation, predicate:  RDF::Vocab::DC.relation,
    #       class_name: 'WithTitle'
    #   end
    #
    #   class WithTitle
    #     include ActiveTriples::RDFSource
    #     property :title, predicate: RDF::Vocab::DC.title
    #   end
    #
    #   resource = WithRelation.new
    #   attributes = { id: 'http://ex.org/moomin', title: 'moomin' }
    #
    #   resource.get_values(:relation).build(attributes)
    #   # => #<ActiveTriples::Resource:0x2b0(#<ActiveTriples::Resource:0x005>)>)
    #
    #   resource.dump :ttl
    #   # => "\n<http://ex.org/moomin> <http://purl.org/dc/terms/title> \"moomin\" .\n\n [ <http://purl.org/dc/terms/relation> <http://ex.org/moomin>] .\n"
    #
    # @todo: clarify class behavior; it is actually tied to type, in some cases.
    #
    # @see RDFSource#attributes=
    # @see http://guides.rubyonrails.org/active_model_basics.html for some
    #   context on ActiveModel attributes.
    def build(attributes={})
      new_subject = attributes.fetch('id') { RDF::Node.new }

      make_node(new_subject).tap do |node|
        node.attributes = attributes.except('id')
        if parent.kind_of? List::ListResource
          parent.list << node
        elsif node.kind_of? RDF::List
          self.push node.rdf_subject
        else
          self.push node
        end
      end
    end

    ##
    # Empties the `Relation`, deleting any associated triples from `parent`.
    #
    # @return [Relation] self; a now empty relation
    def clear
      return self if empty?
      parent.delete([rdf_subject, predicate, nil])
      parent.notify_observers(property)

      self
    end

    ##
    # @note this method behaves somewhat differently from `Array#delete`.
    #   It succeeds on deletion of non-existing values, always returning
    #   `self` unless an error is raised. There is no option to pass a block
    #   to evaluate if the value is not present. This is because access for
    #   `value` depends on query time. i.e. the `Relation` set does not have an
    #   underlying efficient data structure allowing a reliably cheap existence
    #   check.
    #
    # @note symbols are treated as RDF::Nodes by default in
    #   `RDF::Mutable#delete`, but may also represent tokens in statements.
    #   This casts symbols to a literals, which gets us symmetric behavior
    #   between `#set(:sym)` and `#delete(:sym)`.
    #
    # @example deleting a value
    #   resource = MySource.new
    #   resource.title = ['moomin', 'valley']
    #   resource.title.delete('moomin') # => ["valley"]
    #   resource.title # => ['valley']
    #
    # @example note the behavior of unmatched values
    #   resource = MySource.new
    #   resource.title = 'moomin'
    #   resource.title.delete('valley') # => ["moomin"]
    #   resource.title # => ['moomin']
    #
    # @param value [Object] the value to delete from the relation
    # @return [ActiveTriples::Relation] self
    def delete(value)
      value = RDF::Literal(value) if value.is_a? Symbol

      return self if parent.query([rdf_subject, predicate, value]).nil?

      parent.delete([rdf_subject, predicate, value])
      parent.notify_observers(property)
      self
    end

    ##
    # A variation on `#delete`. This queries the relation for matching
    # values before running the deletion, returning `nil` if it does not exist.
    #
    # @param value [Object] the value to delete from the relation
    #
    # @return [Object, nil] `nil` if the value doesn't exist; the value
    #   otherwise
    # @see #delete
    def delete?(value)
      value = RDF::Literal(value) if value.is_a? Symbol

      return nil if parent.query([rdf_subject, predicate, value]).nil?

      delete(value)
      value
    end

    ##
    # Gives a result set for the `Relation`.
    #
    # By default, `RDF::URI` and `RDF::Node` results are cast to `RDFSource`. 
    # When `cast?` is `false`, `RDF::Resource` values are left in their raw 
    # form.
    #
    # `Literal` results are cast as follows:
    # 
    #    - Simple string literals are returned as `String`
    #    - `rdf:langString` literals are always returned as raw `Literal` objects, 
    #       retaining their language tags.
    #    - Typed literals are cast to their Ruby `#object` when their datatype 
    #      is associated with a `Literal` subclass.
    #
    # @example results with default casting
    #   datatype = RDF::URI("http://example.com/custom_type")
    #
    #   parent << [parent.rdf_subject, predicate, 'my value']
    #   parent << [parent.rdf_subject, predicate, RDF::Literal('my_value',
    #                                               datatype: datatype)]
    #   parent << [parent.rdf_subject, predicate, Date.today]
    #   parent << [parent.rdf_subject, predicate, RDF::URI('http://ex.org/#me')]
    #   parent << [parent.rdf_subject, predicate, RDF::Node.new]
    #
    #   relation.to_a
    #   # => ["my_value",
    #   #     "my_value" R:L:(Literal),
    #   #     Fri, 25 Sep 2015,
    #   #     #<ActiveTriples::Resource:0x3f8...>,
    #   #     #<ActiveTriples::Resource:0x3f8...>]
    #
    # @example results with `cast?` set to `false`
    #   relation.to_a
    #   # => ["my_value",
    #   #     "my_value" R:L:(Literal),
    #   #     Fri, 25 Sep 2015,
    #   #     #<RDF::URI:0x3f8... URI:http://ex.org/#me>,
    #   #     #<RDF::Node:0x3f8...(_:g69843536054680)>]
    #
    # @return [Enumerator<Object>] the result set
    def each
      return [].to_enum if predicate.nil?

      if block_given?
        objects do |object|
          converted_object = convert_object(object)
          yield converted_object unless converted_object.nil?
        end
      end

      to_enum
    end

    ##
    # @return [Boolean] true if the results are empty.
    def empty?
      objects.empty?
    end

    ##
    # @deprecated for removal in 1.0.0. Use `first || build({})`,
    #   `build({}) if empty?` or similar logic.
    #
    # @return [Object] the first result, if present; else a newly built node
    #
    # @see #build
    def first_or_create(attributes={})
      warn 'DEPRECATION: #first_or_create is deprecated for removal in 1.0.0.'
      first || build(attributes)
    end

    ##
    # @return [Integer]
    def length
      objects.to_a.length
    end

    ##
    # Gives the predicate used by the Relation. Values of this object are
    # those that match the pattern `<rdf_subject> <predicate> [value] .`
    #
    # @return [RDF::Term, nil] the predicate for this relation; nil if
    #   no predicate can be found
    #
    # @see #property
    def predicate
      return property if property.is_a?(RDF::Term)
      property_config[:predicate] if is_property?
    end

    ##
    # Returns the property for the Relation. This may be a registered
    # property key or an {RDF::URI}.
    #
    # @return [Symbol, RDF::URI]  the property for this Relation.
    # @see #predicate
    def property
      value_arguments.last
    end

    ##
    # Set the values of the Relation
    #
    # @param [Array<RDF::Resource>, RDF::Resource] values  an array of values
    #   or a single value. If not an `RDF::Resource`, the values will be
    #   coerced to an `RDF::Literal` or `RDF::Node` by `RDF::Statement`
    #
    # @return [Relation] a relation containing the set values; i.e. `self`
    #
    # @raise [ActiveTriples::UndefinedPropertyError] if the property is not
    #   already an `RDF::Term` and is not defined in `#property_config`
    #
    # @see http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Statement For
    #   documentation on `RDF::Statement` and the handling of
    #   non-`RDF::Resource` values.
    def set(values)
      raise UndefinedPropertyError.new(property, reflections) if predicate.nil?

      values = prepare_relation(values) if values.is_a?(Relation)
      values = [values].compact unless values.kind_of?(Array)

      clear
      values.each { |val| set_value(val) }
      parent.notify_observers(property)
      
      parent.persist! if parent.persistence_strategy.respond_to?(:ancestors) &&
                         parent.persistence_strategy.ancestors.any? { |r| r.is_a?(ActiveTriples::List::ListResource) }

      self
    end

    ##
    # @overload subtract(enum)
    #   Deletes objects in the enumerable from the relation
    #   @param values [Enumerable] an enumerable of objects to delete
    # @overload subtract(*values)
    #   Deletes each argument value from the relation
    #   @param *values [Array<Object>] the objects to delete
    #
    # @return [Relation] self
    #
    # @note This casts symbols to a literals, which gets us symmetric behavior
    #   with `#set(:sym)`.
    #
    # @note This method treats all calls as changes for the purpose of observer
    #   notifications
    # @see #delete
    def subtract(*values)
      values = values.first if values.first.is_a? Enumerable
      statements = values.map do |value|
        value = RDF::Literal(value) if value.is_a? Symbol
        [rdf_subject, predicate, value]
      end

      parent.delete(*statements)
      parent.notify_observers(property)
      self
    end

    ##
    # Replaces the first argument with the second as a value within the
    # relation.
    #
    # @param swap_out [Object] the value to delete
    # @param swap_in  [Object] the replacement value
    #
    # @return [Relation] self
    def swap(swap_out, swap_in)
      self.<<(swap_in) if delete?(swap_out)
    end

    protected

      ##
      # Converts an object to the appropriate class.
      #
      # Literals are cast only when the datatype is known.
      #
      # @private
      def convert_object(value)
        case value
        when RDFSource
          value
        when RDF::Literal
          if value.simple?
            value.object
          elsif value.has_datatype?
            RDF::Literal.datatyped_class(value.datatype.to_s) ? value.object : value
          else
            value
          end
        when RDF::Resource
          cast? ? make_node(value) : value
        else
          value
        end
      end

      ##
      # @private
      def node_cache
        @node_cache ||= {}
      end

      ##
      # @private
      def objects(&block)
        solutions = parent.query([rdf_subject, predicate, nil])
        solutions.extend(RDF::Enumerable) unless solutions.respond_to?(:each_object)
        
        solutions.each_object(&block)
      end

    private
      ##
      # @private
      def is_property?
        reflections.has_property?(property) || is_type?
      end

      ##
      # @private
      def is_type?
        (property == RDF.type || property.to_s == "type") &&
        (!reflections.kind_of?(RDFSource) || !is_property?)
      end

      ##
      # @private
      # @return [Hash<Symbol, ]
      def property_config
        return TYPE_PROPERTY if is_type?

        reflections.reflect_on_property(property)
      end

      ##
      # @private
      def set_value(val)
        resource = value_to_node(val.respond_to?(:resource) ? val.resource : val)
        if resource.kind_of? RDFSource
          node_cache[resource.rdf_subject] = nil
          add_child_node(val, resource)
          return
        end
        resource = resource.to_uri if resource.respond_to? :to_uri
        raise ValueError, resource unless resource.kind_of? RDF::Term
        parent.insert [rdf_subject, predicate, resource]
      end

      ##
      # @private
      def value_to_node(val)
        valid_datatype?(val) ? RDF::Literal(val) : val
      end

      def prepare_relation(values)
        values.objects.map do |value|
          if value.respond_to?(:resource?) && value.resource?
            values.convert_object(value)
          else
            value
          end  
        end
      end

      ##
      # @private
      def add_child_node(object, resource)
        parent.insert [rdf_subject, predicate, resource.rdf_subject]
        resource = resource.respond_to?(:resource) ? resource.resource : resource

        new_resource = resource.dup unless object.respond_to?(:resource) && object.resource == resource
        new_resource ||= resource
        unless new_resource == parent ||
               (parent.persistence_strategy.is_a?(ParentStrategy) &&
                parent.persistence_strategy.ancestors.find { |a| a == new_resource })
          new_resource.set_persistence_strategy(ParentStrategy)
          new_resource.parent = parent
        end

        self.node_cache[resource.rdf_subject] = (resource == object ? new_resource : object)
      end

      ##
      # @private
      def valid_datatype?(val)
        case val
        when String, Date, Time, Numeric, Symbol, TrueClass, FalseClass then true
        else false
        end
      end

      ##
      # Build a child resource or return it from this object's cache
      #
      # Builds the resource from the class_name specified for the
      # property.
      #
      # @private
      def make_node(value)
        klass = class_for_value(value)
        value = RDF::Node.new if value.nil?

        return node_cache[value] if node_cache[value]

        node = klass.from_uri(value, parent)

        if is_property? && property_config[:persist_to]
          node.set_persistence_strategy(property_config[:persist_to])

          node.persistence_strategy.parent = parent if
            node.persistence_strategy.is_a?(ParentStrategy)
        end

        self.node_cache[value] ||= node
      end

      ##
      # @private
      def cast?
        return true unless is_property? || rel_args[:cast]
        return rel_args[:cast] if rel_args.has_key?(:cast)
        !!property_config[:cast]
      end

      ##
      # @private
      def final_parent
        @final_parent ||= begin
          parent = self.parent
          while parent != parent.parent && parent.parent
            parent = parent.parent
          end
          return parent.datastream if parent.respond_to?(:datastream) && parent.datastream
          parent
        end
      end

      ##
      # @private
      def class_for_value(v)
        uri_class(v) || class_for_property
      end

      ##
      # @private
      def uri_class(v)
        v = RDF::URI.intern(v) if v.kind_of? String
        type_uri = parent.query([v, RDF.type, nil]).to_a.first.try(:object)
        RDFSource.type_registry[type_uri]
      end

      ##
      # @private
      def class_for_property
        klass = property_config[:class_name] if is_property?
        klass ||= Resource
        klass = ActiveTriples.class_from_string(klass, final_parent.class) if
          klass.kind_of? String
        klass
      end

      ##
      # @private
      # @return [RDF::Term] the subject of the relation
      def rdf_subject
        if value_arguments.length < 1 || value_arguments.length > 2
          raise(ArgumentError,
                "wrong number of arguments (#{value_arguments.length} for 1-2)")
        end

        value_arguments.length > 1 ? value_arguments.first : parent.rdf_subject
      end

    public

    ##
    # An error class for unallowable values in relations.
    class ValueError < ArgumentError
      # @!attribute [r] value
      attr_reader :value

      ##
      # @param value [Object]
      def initialize(value)
        @value = value
      end

      ##
      # @return [String]
      def message
        'value must be an RDF URI, Node, Literal, or a valid datatype. '\
        "See RDF::Literal.\n\tYou provided #{value.inspect}"
      end
    end
  end
end
