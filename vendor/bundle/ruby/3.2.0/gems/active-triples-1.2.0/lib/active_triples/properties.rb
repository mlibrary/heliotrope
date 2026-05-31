# frozen_string_literal: true
require 'active_support/core_ext/hash'

module ActiveTriples
  ##
  # Implements property configuration in the style of RDFSource. It does its 
  # work at the class level, and is meant to be extended.
  # 
  # Collaborates closely with ActiveTriples::Reflection
  #
  # @example define properties at the class level
  #
  #    property :title, predicate: RDF::DC.title, class_name: ResourceClass
  #
  # @example using property setters & getters
  #    resource.property :title, predicate: RDF::DC.title, 
  #                              class_name: ResourceClass
  #
  #    resource.title = 'Comet in Moominland'
  #
  #    resource.title                # => ['Comet in Moominland']
  #    resource.title(literal: true) # => [RDF::Literal('Comet in Moominland')]
  #
  # @see {ActiveTriples::Reflection}
  # @see {ActiveTriples::PropertyBuilder}
  module Properties
    extend ActiveSupport::Concern

    included do
      include Reflection
      initialize_generated_modules
    end

    private

      ##
      # Returns the properties registered and their configurations.
      #
      # @return [ActiveSupport::HashWithIndifferentAccess{String => ActiveTriples::NodeConfig}]
      def properties
        _active_triples_config
      end

      ##
      # Lists fields registered as properties on the object.
      #
      # @return [Array<Symbol>] the list of registered properties.
      def fields
        properties.keys.map(&:to_sym).reject{ |x| x == :type }
      end

      ##
      # List of RDF predicates registered as properties on the object.
      #
      # @return [Array<RDF::URI>]
      def registered_predicates
        properties.values.map { |config| config.predicate }
      end

      ##
      # List of RDF predicates used in the Resource's triples, but not
      # mapped to any property or accessor methods.
      #
      # @return [Array<RDF::URI>]
      def unregistered_predicates
        registered_preds   = registered_predicates << RDF.type
        unregistered_preds = []

        query([rdf_subject, nil, nil]) do |stmt|
          unregistered_preds << stmt.predicate unless
            registered_preds.include? stmt.predicate
        end

        unregistered_preds
      end

    public
    
    ##
    # Class methods for classes with `Properties`
    module ClassMethods
      def inherited(child_class) #:nodoc:
        child_class.initialize_generated_modules
        super
      end

      ##
      # If the property methods are not yet present, generates them.
      #
      # @return [Module] a module self::GeneratedPropertyMethods which is 
      #   included in self and defines the property methods
      #
      # @note this is an alias to #generated_property_methods. Use it when you 
      #   intend to initialize, rather than retrieve, the methods for code
      #   readability
      # @see #generated_property_methods
      def initialize_generated_modules
        generated_property_methods
      end

      ##
      # Gives existing generated property methods. If the property methods are 
      # not yet present, generates them as a new Module and includes it.
      #
      # @return [Module] a module self::GeneratedPropertyMethods which is 
      #   included in self and defines the property methods
      #
      # @note use the alias #initialize_generated_modules for clarity of intent
      #   where appropriate
      # @see #initialize_generated_modules
      def generated_property_methods
        @generated_property_methods ||= begin
          mod = const_set(:GeneratedPropertyMethods, Module.new)
          include mod
          mod
        end
      end

      ##
      # Registers properties for Resource-like classes
      #
      # @param [Symbol]  name of the property (and its accessor methods)
      # @param [Hash]  opts for this property, must include a :predicate
      # @yield [index] index sets solr behaviors for the property
      #
      # @return [Hash{String=>ActiveTriples::NodeConfig}] the full current
      #   property configuration for the class
      def property(name, opts={}, &block)
        raise ArgumentError, "#{name} is a keyword and not an acceptable property name." if protected_property_name?(name.to_sym)
        reflection = PropertyBuilder.build(self, name, opts, &block)
        Reflection.add_reflection self, name, reflection
      end

      ##
      # Checks potential property names for conflicts with existing class
      # instance methods. We avoid setting properties with these names to
      # prevent catastrophic method overwriting.
      #
      # @param [Symblol] name  A potential property name.
      # @return [Boolean] true if the given name matches an existing instance
      #   method which is not an ActiveTriples property.
      def protected_property_name?(name)
        return false if fields.include?(name)
        return true if instance_methods.include?(name) || instance_methods.include?("#{name}=".to_sym)
        false
      end

      ##
      # Given a property name or a predicate, return the configuration
      # for the matching property.
      #
      # @param [#to_sym, RDF::Resource] term  property name or predicate
      #
      # @return [ActiveTriples::NodeConfig] the configuration for the property
      def config_for_term_or_uri(term)
        return properties[term.to_s] unless
          term.is_a?(RDF::Resource) && !term.is_a?(RDFSource)
        properties.each_value { |v| return v if v.predicate == term.to_uri }
      end

      ##
      # List the property names registered to the class.
      #
      # @return [Array<Symbol>] list of the symbolized names of registered
      #   properties
      def fields
        properties.keys.map(&:to_sym)
      end
    end
  end
end
