# frozen_string_literal: true
require 'active_model'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/array/wrap'
require 'set'

module ActiveTriples
  ##
  # Defines a concern for managing {RDF::Graph} driven Resources as discrete,
  # stateful graphs using ActiveModel-style objects.
  #
  # An `RDFSource` models a resource ({RDF::Resource}) with a state that may
  # change over time. The current state is represented by an {RDF::Graph},
  # accessible as {#graph}. The source is an {RDF::Resource} represented by
  # {#rdf_subject}, which may be either an {RDF::URI} or an {RDF::Node}.
  #
  # The graph of a source may contain contain arbitrary triples, including full
  # representations of the state of other sources. The triples in the graph
  # should be limited to statements that have bearing on the resource's state.
  #
  # Properties may be defined on inheriting classes to configure accessor
  # methods for predicates.
  #
  # @example
  #    class License
  #      include Active::Triples::RDFSource
  #
  #      configure repository: :default
  #      property :title, predicate: RDF::DC.title, class_name: RDF::Literal
  #    end
  #
  # @see http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/#change-over-time
  #   RDF Concepts and Abstract Syntax comment on "RDF source"
  # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-rdf-source an
  #   example of the RDF source concept as defined in the LDP specification
  #
  # An `RDFSource` is an {RDF::Term}---it can be used as a subject, predicate,
  # object, or context in an {RDF::Statement}.
  #
  # @todo complete RDF::Value/RDF::Term/RDF::Resource interfaces
  #
  # @see ActiveModel
  # @see RDF::Resource
  # @see RDF::Queryable
  module RDFSource
    extend ActiveSupport::Concern

    include NestedAttributes
    include Persistable
    include Properties
    include RDF::Value
    include RDF::Queryable
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    def type_registry
      @@type_registry ||= {}
    end
    module_function :type_registry

    included do
      extend Configurable
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      extend ActiveModel::Callbacks

      validate do
        errors.add(:rdf_subject, 'The #rdf_subject Term must be valid') unless
          rdf_subject.valid?
        errors.add(:base, 'The underlying graph must be valid') unless
          graph.valid?
      end

      define_model_callbacks :persist
    end

    ##
    # @!method count
    #   @return (see RDF::Graph#count)
    # @!method each
    #   @return (see RDF::Graph#each)
    # @!method load!
    #   @return (see RDF::Graph#load!)
    # @!method has_statement?
    #   @return (see RDF::Graph#has_statement?)
    # @!method query
    #   @return (see RDF::Graph#query)
    delegate :query, :each, :load!, :count, :has_statement?, to: :graph

    ##
    # @!method to_base
    #   @return (see RDF::Term#to_base)
    # @!method escape
    #   @return (see RDF::Term#escape)
    delegate :to_base, :escape, to: :to_term

    ##
    # Initialize an instance of this resource class. Defaults to a
    # blank node subject. In addition to RDF::Graph parameters, you
    # can pass in a URI and/or a parent to build a resource from a
    # existing data.
    #
    # You can pass in only a parent with:
    #    new(nil, parent)
    #
    # @see RDF::Graph
    # @todo move this logic out to a Builder?
    def initialize(*args, &block)
      @observers = Set.new

      resource_uri = args.shift unless args.first.is_a?(Hash)
      @rdf_subject = get_uri(resource_uri) if resource_uri

      if args.first.is_a?(Hash) || args.empty?
        set_persistence_strategy(RepositoryStrategy)
      else
        set_persistence_strategy(ParentStrategy)
        persistence_strategy.parent = args.shift
      end

      graph_params = if args.empty? || args.first.nil?
                       {}
                     else
                       args.shift
                     end
      persistence_strategy.graph = RDF::Graph.new(**graph_params, &block)
      reload

      # Append type to graph if necessary.
      Array.wrap(self.class.type).each do |type|
        get_values(:type) << type unless get_values(:type).include?(type)
      end
    end

    ##
    # Compares self to other for {RDF::Term} equality.
    #
    # Delegates the check to `other#==` passing it the term version of `self`.
    #
    # @param other [Object]
    #
    # @see RDF::Term#==
    # @see RDF::Node#==
    # @see RDF::URI#==
    def ==(other)
      other == to_term
    end

    ##
    # Gives a hash containing both the registered and unregistered attributes of
    # the resource. Unregistered attributes are given with full URIs.
    #
    # @example
    #   class WithProperties
    #     include ActiveTriples::RDFSource
    #     property :title,   predicate:  RDF::Vocab::DC.title
    #     property :creator, predicate:  RDF::Vocab::DC.creator,
    #                        class_name: 'Agent'
    #   end
    #
    #   class Agent; include ActiveTriples::RDFSource; end
    #
    #   resource = WithProperties.new
    #
    #   resource.attributes
    #   # => {"id"=>"g47123700054720", "title"=>[], "creator"=>[]}
    #
    #   resource.creator.build
    #   resource.title << ['Comet in Moominland', 'Christmas in Moominvalley']
    #
    #   resource.attributes
    #   # => {"id"=>"g47123700054720",
    #   #     "title"=>["Comet in Moominland", "Christmas in Moominvalley"],
    #   #     "creator"=>[#<Agent:0x2adbd76f1a5c(#<Agent:0x0055b7aede34b8>)>]}
    #
    #   resource << [resource, RDF::Vocab::DC.relation, 'Helsinki']
    #   # => {"id"=>"g47123700054720",
    #   #     "title"=>["Comet in Moominland", "Christmas in Moominvalley"],
    #   #     "creator"=>[#<Agent:0x2adbd76f1a5c(#<Agent:0x0055b7aede34b8>)>],
    #   #     "http://purl.org/dc/terms/relation"=>["Helsinki"]}]}
    #
    # @return [Hash<String, Array<Object>>]
    #
    # @todo: should this, `#attributes=`, and `#serializable_hash` be moved out
    #   into a dedicated `Serializer` object?
    def attributes
      attrs = {}
      attrs['id'] = id
      fields.map { |f| attrs[f.to_s] = get_values(f) }
      unregistered_predicates.map { |uri| attrs[uri.to_s] = get_values(uri) }
      attrs
    end

    def attributes=(values)
      raise(ArgumentError, "values must be a Hash. Got: #{values.class}") unless
        values.is_a? Hash

      values = values.with_indifferent_access
      id = values.delete(:id)
      set_subject!(id) if node? && id && get_uri(id).uri?

      values.each do |key, value|
        if reflections.has_property?(key)
          set_value(key, value)
        elsif nested_attributes_options
              .keys.any? { |k| key == "#{k}_attributes" }
          send("#{key}=".to_sym, value)
        else
          raise ArgumentError, "No association found for name `#{key}'. " \
                               'Has it been defined yet?'
        end
      end
    end

    ##
    # @return [Array<RDF::URI>] a group of properties to use for default labels.
    def default_labels
      [RDF::Vocab::SKOS.prefLabel,
       RDF::Vocab::DC.title,
       RDF::RDFS.label,
       RDF::Vocab::SKOS.altLabel,
       RDF::Vocab::SKOS.hiddenLabel]
    end

    ##
    # @return [Hash]
    def serializable_hash(*)
      attrs = fields.map(&:to_s) << 'id'
      hash = super(only: attrs)
      unregistered_predicates.map { |uri| hash[uri.to_s] = get_values(uri) }

      hash
    end

    ##
    # Returns a serialized string representation of self.
    # Extends the base implementation builds a JSON-LD context if the
    # specified format is :jsonld and a context is provided by
    # #jsonld_context
    #
    # @see RDF::Enumerable#dump
    #
    # @param args [Array<Object>]
    # @return [String]
    def dump(*args)
      if args.first == :jsonld && respond_to?(:jsonld_context)
        args << {} unless args.last.is_a?(Hash)
        args.last[:context] ||= jsonld_context
      end
      super
    end

    ##
    # Delegate parent to the persistence strategy if possible
    #
    # @todo establish a better pattern for this. `#parent` has been a public
    #   method in the past, but it's probably time to deprecate it.
    def parent
      return persistence_strategy.parent if
        persistence_strategy.respond_to?(:parent)

      nil
    end

    ##
    # @todo deprecate/remove
    # @see #parent
    def parent=(parent)
      return persistence_strategy.parent = parent if
        persistence_strategy.respond_to?(:parent=)

      nil
    end

    ##
    # Gives the representation of this RDFSource as an RDF::Term
    #
    # @return [RDF::URI, RDF::Node] the URI that identifies this `RDFSource`;
    #   or a bnode identifier
    #
    # @see RDF::Term#to_term
    def rdf_subject
      @rdf_subject ||= RDF::Node.new
    end
    alias to_term rdf_subject

    ##
    # Returns `nil` as the `graph_name`. This behavior mimics an `RDF::Graph`
    # with no graph name, or one without named graph support.
    #
    # @note: it's possible to think of an `RDFSource` as "supporting named
    #   graphs" in the sense that the `#rdf_subject` is an implied graph name.
    #   For RDF.rb's purposes, however, it has a nil graph name: when
    #   enumerating statements, we treat them as triples.
    #
    # @return [nil]
    # @sse RDF::Graph.graph_name
    def graph_name
      nil
    end

    ##
    # @return [String] A string identifier for the resource; '' if the
    #   resource is a node
    def humanize
      node? ? '' : rdf_subject.to_s
    end

    ##
    # @return [RDF::URI] the uri
    def to_uri
      rdf_subject if uri?
    end

    ##
    # @return [String]
    #
    # @see RDF::Node#id
    def id
      node? ? rdf_subject.id : rdf_subject.to_s
    end

    ##
    # @return [String]
    #
    # @note Without a custom #inspect, we inherit from RDF::Value.
    def inspect
      sprintf("#<%s:%#0x ID:%s>", self.class.to_s, self.object_id, self.to_base)
    end

    ##
    # @return [Boolean] true if the Term is a node
    #
    # @see RDF::Term#node?
    def node?
      rdf_subject.node?
    end

    ##
    # @return [Boolean] true if the Term is a uri
    #
    # @see RDF::Term#uri?
    def uri?
      rdf_subject.uri?
    end

    ##
    # @return [String, nil] the base URI the resource will use when
    #   setting its subject. `nil` if none is used.
    def base_uri
      self.class.base_uri
    end

    def type
      get_values(:type)
    end

    def type=(type)
      raise(ArgumentError,
            "Type must be an RDF::URI. Got: #{type.class}, #{type}") unless
        type.is_a? RDF::URI

      update(RDF::Statement.new(rdf_subject, RDF.type, type))
    end

    ##
    # Looks for labels in various default fields, prioritizing
    # configured label fields.
    #
    # @see #default_labels
    def rdf_label
      labels = Array.wrap(self.class.rdf_label)
      labels += default_labels
      labels.each do |label|
        values = get_values(label)
        return values unless values.empty?
      end
      node? ? [] : [rdf_subject.to_s]
    end

    ##
    # Load data from the #rdf_subject URI. Retrieved data will be
    # parsed into the Resource's graph from available RDF::Readers
    # and available from property accessors if if predicates are
    # registered.
    #
    # @example
    #    osu = new('http://dbpedia.org/resource/Oregon_State_University')
    #    osu.fetch
    #    osu.rdf_label.first
    #    # => "Oregon State University"
    #
    # @example with default action block
    #    my_source = new('http://example.org/dead_url')
    #    my_source.fetch { |obj| obj.status = 'dead link' }
    #
    # @yield gives self to block if this is a node, or an error is raised during
    #   load
    # @yieldparam [ActiveTriples::RDFSource] resource  self
    #
    # @return [ActiveTriples::RDFSource] self
    def fetch(**args, &_block)
      begin
        load(rdf_subject, **args)
      rescue => e
        if block_given?
          yield(self)
        else
          raise "#{self} is a blank node; " \
                'Cannot fetch a resource without a URI' if node?
          raise e
        end
      end
      self
    end

    ##
    # Adds or updates a property by creating triples for each of the supplied
    # values.
    #
    # The `property` argument may be either a symbol representing a registered
    # property name, or an RDF::Term to use as the predicate.
    #
    # @example setting with a property name
    #   class Thing
    #     include ActiveTriples::RDFSource
    #     property :creator, predicate: RDF::DC.creator
    #   end
    #
    #   t = Thing.new
    #   t.set_value(:creator, 'Tove Jansson')  # => ['Tove Jansson']
    #
    #
    # @example setting with a predicate
    #   t = Thing.new
    #   t.set_value(RDF::DC.creator, 'Tove Jansson')  # => ['Tove Jansson']
    #
    #
    # The recommended pattern, which sets properties directly on this
    # RDFSource, is: `set_value(property, values)`
    #
    # @overload set_value(property, values)
    #   Updates the values for the property, using this RDFSource as the subject
    #
    #   @param [RDF::Term, #to_sym] property  a symbol with the property name
    #     or an RDF::Term to use as a predicate.
    #   @param [Array<RDF::Resource>, RDF::Resource] values  an array of values
    #     or a single value. If not an {RDF::Resource}, the values will be
    #     coerced to an {RDF::Literal} or {RDF::Node} by {RDF::Statement}
    #
    # @overload set_value(subject, property, values)
    #   Updates the values for the property, using the given term as the subject
    #
    #   @param [RDF::Term] subject  the term representing the
    #   @param [RDF::Term, #to_sym] property  a symbol with the property name
    #     or an RDF::Term to use as a predicate.
    #   @param [Array<RDF::Resource>, RDF::Resource] values  an array of values
    #     or a single value. If not an {RDF::Resource}, the values will be
    #     coerced to an {RDF::Literal} or {RDF::Node} by {RDF::Statement}
    #
    # @return [ActiveTriples::Relation] an array {Relation} containing the
    #   values of the property
    #
    # @raise [ActiveTriples::Relation::ValueError] when the given value can't be
    #   coerced into an acceptable `RDF::Term`.
    #
    # @note This method will delete existing statements with the given
    #   subject and predicate from the graph
    #
    # @see http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Statement For
    #   documentation on {RDF::Statement} and the handling of
    #   non-{RDF::Resource} values.
    def set_value(*args)
      # Add support for legacy 3-parameter syntax
      if args.length > 3 || args.length < 2
        raise ArgumentError,
              "wrong number of arguments (#{args.length} for 2-3)"
      end
      values = args.pop
      get_values(*args).set(values)
    end

    ##
    # Returns an array of values belonging to the property
    # requested. Elements in the array may RdfResource objects or a
    # valid datatype.
    #
    # Handles two argument patterns. The recommended pattern, which accesses
    # properties directly on this RDFSource, is:
    #    get_values(property)
    #
    # @overload get_values(property)
    #   Gets values on the RDFSource for the given property
    #   @param [String, #to_term] property  the property for the values
    #
    # @overload get_values(uri, property)
    #   For backwards compatibility, explicitly passing the term used as the
    #   subject {ActiveTriples::Relation#rdf_subject} of the returned relation.
    #   @param [RDF::Term] uri  the term to use as the subject
    #   @param [String, #to_term] property  the property for the values
    #
    # @return [ActiveTriples::Relation] an array {Relation} containing the
    #   values of the property
    #
    # @todo should this raise an error when the property argument is not an
    #   {RDF::Term} or a registered property key?
    def get_values(*args)
      @relation_cache ||= {}
      rel = Relation.new(self, args)
      @relation_cache["#{rel.send(:rdf_subject)}/#{rel.property}/#{rel.rel_args}"] ||= rel
      @relation_cache["#{rel.send(:rdf_subject)}/#{rel.property}/#{rel.rel_args}"]
    end

    ##
    # Returns an array of values belonging to the property requested. Elements
    # in the array may RdfResource objects or a valid datatype.
    #
    # @param [RDF::Term, :to_s] term_or_property
    def [](term_or_property)
      get_values(term_or_property)
    end

    ##
    # Adds or updates a property with supplied values.
    #
    # @param [RDF::Term, :to_s] term_or_property
    # @param [Array<RDF::Resource>, RDF::Resource] values  an array of values
    #   or a single value to set the property to.
    #
    # @note This method will delete existing statements with the correct
    #   subject and predicate from the graph
    def []=(term_or_property, value)
      self[term_or_property].set(value)
    end

    ##
    # @deprecated for removal in 1.0; use `#get_values` insctead.
    # @see #get_values
    def get_relation(args)
      warn 'DEPRECATION: `ActiveTriples::RDFSource#get_relation` will be' \
           'removed in 1.0; use `#get_values` instead.'
      get_values(*args)
    end

    ##
    # Set a new rdf_subject for the resource.
    #
    # Will try to build a uri as an extension of the class's base_uri
    # if appropriate.
    #
    # @param  [#to_uri, #to_s] uri_or_str the uri or string to use
    # @return [void]
    #
    # @raise if the current subject is not a blank node,
    #   and returns false if it can't figure out how to make a URI from
    #   the param. Otherwise it creates a URI for the resource and
    #   rebuilds the graph with the updated URI.
    def set_subject!(uri_or_str)
      raise 'Refusing to update URI when one is already assigned!' unless
        node? || rdf_subject == RDF::URI(nil)

      return if uri_or_str.nil? ||
                (uri_or_str.to_s.empty? && !uri_or_str.is_a?(RDF::URI))

      new_subject = get_uri(uri_or_str)
      rewrite_statement_uris(rdf_subject, new_subject)

      @rdf_subject = new_subject
    end

    ##
    # Indicates if the record is 'new' (has not yet been persisted).
    #
    # @return [Boolean]
    def new_record?
      !persisted?
    end

    ##
    # @overload term?
    #   Returns `false` indicating this is not an RDF::Statemenet.
    #   @see RDF::Value#statement?
    #   @return [Boolean]
    # @overload term?(value)
    #   Returns `true` if `self` contains the given RDF subject term.
    #
    #   @param  [RDF::Resource] value
    #   @return [Boolean]
    #
    # See RDF::Enumerable#term?
    def term?(*args)
      case args.length
      when 0 then to_term.term?
      when 1 then args.first && graph.term?(args.first)
      else raise ArgumentError("wrong number of arguments (given #{args.length}, expected 0 or 1)")
      end
    end

    def mark_for_destruction
      @marked_for_destruction = true
    end

    def marked_for_destruction?
      @marked_for_destruction
    end

    ##
    # @param observer [#notify]
    #
    # @retern [#notify] the added observer
    def add_observer(observer)
      @observers.add(observer)
    end

    ##
    # @param observer [#notify] an observer to delete
    #
    # @return [#notify, nil] the deleted observer; nil if the observer was not
    #   registered
    def delete_observer(observer)
      @observers.delete?(observer)
    end

    ##
    # Sends `#notify` messages with the property symbol and the current values
    # for the property to each observer.
    #
    # @note We short circuit to avoid query costs if no observers are present.
    #   If there are regisetred observers, values are returned as an array.
    #   This means that we incur query costs immediately and only once.
    #
    # @example Setting up observers
    #    class MyObserver
    #      def notify(property, values)
    #        # do something
    #      end
    #    end
    #
    #    observer = MyObserver.new
    #    my_source.add_observer(observer)
    #
    #    my_source.creator = 'Moomin'
    #    # the observer recieves a #notify(:creator, ['Moomin']) message here.
    #
    # @param property [Symbol]
    #
    # @return [void]
    def notify_observers(property)
      return if @observers.empty?
      values = get_values(property).to_a
      @observers.each { |o| o.notify(property, values) }
    end

    private

    ##
    # Rewrites the subject and object of each statement containing
    # `old_subject` in either position. Used when setting the subject to
    # remove the placeholder blank node subjects.
    #
    # @param [RDF::Term] old_subject
    # @param [RDF::Term] new_subject
    # @return [void]
    def rewrite_statement_uris(old_subject, new_subject)
      graph.query([old_subject, nil, nil]).each do |st|
        graph.delete(st)

        st.subject = new_subject
        st.object  = new_subject if st.object == old_subject
        graph.insert(st)
      end

      graph.query([nil, nil, old_subject]).each do |st|
        graph.delete(st)

        st.object = new_subject
        graph.insert(st)
      end
    end

    ##
    # Takes a URI or String and aggressively tries to convert it into
    # an RDF term. If a String is given, first tries to interpret it
    # as a valid URI, then tries to append it to base_uri. Finally,
    # raises an error if no valid term can be built.
    #
    # The argument must be an RDF::Node, an object that responds to
    # #to_uri, a String that represents a valid URI, or a String that
    # appends to the Resource's base_uri to create a valid URI.
    #
    # @TODO: URI.scheme_list is naive and incomplete. Find a better
    #   way to check for an existing scheme.
    #
    # @param uri_or_str [RDF::Resource, String]
    #
    # @return [RDF::Resource] A term
    # @raise [RuntimeError] no valid RDF term could be built
    def get_uri(uri_or_str)
      return uri_or_str.to_term if uri_or_str.respond_to? :to_term

      uri_or_node = RDF::Resource.new(uri_or_str)
      return uri_or_node if uri_or_node.valid?

      uri_or_str = uri_or_str.to_s
      return RDF::URI.intern(base_uri.to_s) / uri_or_str if
        base_uri && !uri_or_str.start_with?(base_uri.to_s)

      raise "could not make a valid RDF::URI from #{uri_or_str}"
    end

    ##
    # Class methods for RDFSource, included via ActiveSupport
    module ClassMethods
      ##
      # Adapter for a consistent interface for creating a new Resource
      # from a URI. Similar functionality should exist in all objects
      # which can become a Resource.
      #
      # @param uri [#to_uri, String]
      # @param args values to pass as arguments to ::new
      #
      # @return [ActiveTriples::Entity] a Resource with the given uri
      def from_uri(uri, *args)
        new(uri, *args)
      end

      ##
      # Apply a predicate mapping using a given strategy.
      #
      # @param [ActiveTriples::Schema, #properties] schema A schema to apply.
      # @param [#apply!] strategy A strategy for applying. Defaults
      #   to ActiveTriples::ExtensionStrategy
      def apply_schema(schema, strategy = ActiveTriples::ExtensionStrategy)
        schema.properties.each { |property| strategy.apply(self, property) }
      end

      ##
      # Test if the rdf_subject that would be generated using a
      # specific ID is already in use in the triplestore.
      #
      # @param [Integer, #read] ID to test
      #
      # @return [TrueClass, FalseClass] true, if the ID is in
      #    use in the triplestore; otherwise, false.
      #    NOTE: If the ID is in use in an object not yet
      #          persisted, false will be returned presenting
      #          a window of opportunity for an ID clash.
      def id_persisted?(test_id)
        rdf_subject = new(test_id).rdf_subject

        ActiveTriples::Repositories.has_subject?(rdf_subject)
      end

      ##
      # Test if the rdf_subject that would be generated using a
      # specific URI is already in use in the triplestore.
      #
      # @param [String, RDF::URI, #read] URI to test
      #
      # @return [TrueClass, FalseClass] true, if the URI is in
      #    use in the triplestore; otherwise, false.
      #    NOTE: If the URI is in use in an object not yet
      #          persisted, false will be returned presenting
      #          a window of opportunity for an ID clash.
      def uri_persisted?(test_uri)
        test_uri = RDF::URI.intern(test_uri) unless test_uri.is_a?(RDF::URI)

        ActiveTriples::Repositories.has_subject?(test_uri)
      end
    end
  end
end
