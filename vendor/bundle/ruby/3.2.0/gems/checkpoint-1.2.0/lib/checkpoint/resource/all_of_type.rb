# frozen_string_literal: true

module Checkpoint
  class Resource
    # Specialized Resource type to represent all entities of a particular type.
    class AllOfType < Resource
      attr_reader :type
      # Create a wildcard Resource for a given type
      def initialize(type)
        @type = type
      end

      # This is always the special ALL resource ID
      def id
        Resource::ALL
      end

      # Compares with another Resource
      #
      # @return [Boolean] true if `other` is a Resource and its #type matches.
      def eql?(other)
        other.is_a?(Resource) && type == other.type
      end

      alias_method :==, :eql?
    end
  end
end
