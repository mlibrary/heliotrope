# frozen_string_literal: true
require 'active_support/core_ext/class'

module ActiveTriples
  module Reflection
    extend ActiveSupport::Concern

    included do
      class_attribute :_active_triples_config
      self._active_triples_config = {}
    end

    ##
    # Gives access to a `Reflection` of the properties configured on this class
    #
    # @example
    #   my_source.reflections.has_property?(:title)
    #   my_source.reflections.reflect_on_property(:title)
    # @return [Class] gives `self#class`
    #
    def reflections
      self.class
    end

    def self.add_reflection(model, name, reflection)
      model._active_triples_config = 
        model._active_triples_config.merge(name.to_s => reflection)
    end

    module ClassMethods
      ##
      # @param [#to_s] property
      #
      # @return [ActiveTriples::NodeConfig] the configuration for the property
      #
      # @raise [ActiveTriples::UndefinedPropertyError] when the property does 
      #   not exist
      def reflect_on_property(property)
        _active_triples_config.fetch(property.to_s) do
          raise ActiveTriples::UndefinedPropertyError.new(property.to_s, self)
        end
      end

      ##
      # @return [Hash{String=>ActiveTriples::NodeConfig}] a hash of property 
      #   names and their configurations
      def properties
        _active_triples_config
      end

      ##
      # @param [Hash{String=>ActiveTriples::NodeConfig}] a complete config hash
      #   to set the properties to.
      # @return [Hash{String=>ActiveTriples::NodeConfig}] a hash of property 
      #   names and their configurations
      def properties=(val)
        self._active_triples_config = val
      end

      ##
      # @param [#to_s] property
      #
      # @return [Boolean] true if the property exsits; false otherwise
      def has_property?(property)
        _active_triples_config.keys.include? property.to_s
      end
    end
  end
end
