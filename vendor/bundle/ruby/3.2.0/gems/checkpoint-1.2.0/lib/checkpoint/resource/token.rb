# frozen_string_literal: true

require "checkpoint/resource/resolver"

module Checkpoint
  class Resource
    # A Resource::Token is an identifier object for a Resource. It includes a
    # type and an identifier. A {Grant} can be created for a Token. Concrete
    # entities are resolved into a number of resources, and those resources'
    # tokens will be checked for matching grants.
    class Token
      attr_reader :type, :id

      # Create a new Resource representing a domain entity or concept that would
      # be acted upon.
      #
      # @param type [String] the application-determined type of this resource.
      #   This might correspond to a model class or other type of named concept
      #   in the application. The type is always coerced to String with `#to_s`
      #   in case something else is supplied.
      #
      # @param id [String] the application-resolvable identifier for this
      #   resource. For example, this might be the ID of a model object, the
      #   name of a section. The id is always coerced to String with `#to_s` in
      #   case something else is supplied.
      def initialize(type, id)
        @type = type.to_s
        @id = id.to_s
      end

      # Get the special "all" Resource Token. This is a singleton that represents all
      # resources of all types. It is used to grant permissions or roles within
      # a zone, but not specific to a particular resource.
      #
      # @return [Resource::Token] the special "all" Resource Token
      def self.all
        @all ||= new(Resource::ALL, Resource::ALL).freeze
      end

      # Test whether this token is for the special "all" Resource.
      #
      # @return [Boolean] true if this token represents any/all resources
      def all?
        type == Resource::ALL && id == Resource::ALL
      end

      # Test whether this token is a wildcard for some specific type.
      #
      # @return [Boolean] true if this token has a specific type, but
      #   represents any/all resources of that type
      def all_of_type?
        type != Resource::ALL && id == Resource::ALL
      end

      # @return [Token] self; for convenience of taking a Resource or token
      def token
        self
      end

      # @return [String] a URI for this resource, including its type and id
      def uri
        "resource://#{type}/#{id}"
      end

      # @return [String] a token suitable for granting or matching this resource
      def to_s
        "#{type}:#{id}"
      end

      # Compare with another Resource for equality. Consider them to represent
      # the same resource if `other` is a Resource, has the same type, and same id.
      def eql?(other)
        other.is_a?(Resource::Token) && type == other.type && id == other.id
      end

      # @return [Integer] hash code based on to_s
      def hash
        to_s.hash
      end

      alias_method :==, :eql?
      alias_method :inspect, :uri
      alias_method :resource_type, :type
      alias_method :resource_id, :id
    end
  end
end
