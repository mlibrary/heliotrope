# frozen_string_literal: true

module Checkpoint
  class Resource
    # Special class to represent any entity of a type. This is used for
    # type-wide grants or checks. It is basically so {AllOfType} can
    # have an entity rather than a nil.
    #
    # Wildcards or null objects typically have somewhat strange semantics, and
    # this is no exception. It will compare as eql? and == to any object that
    # has the same type attribute.
    class AnyEntityOfType
      attr_reader :type

      # Create a wildcard entity that will compare as equal to
      def initialize(type)
        @type = type
      end

      # Always returns true; this wildcard is "equal" to any object.
      # return [Boolean] true
      def eql?(other)
        other.respond_to?(:type) && type == other.type
      end

      alias_method :==, :eql?
    end
  end
end
