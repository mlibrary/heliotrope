# frozen_string_literal: true

module Checkpoint
  class Resource
    # Specialized Resource type to represent all entities of a any/all types.
    # This is used for zone-/system-wide grants or checks.
    class AllOfAnyType < Resource
      # Create a wildcard Resource.
      #
      # Because type and ID are static, this takes no parameters
      def initialize
        @entity = AnyEntity.new
      end

      # The special ALL type
      def type
        Resource::ALL
      end

      # The special ALL id
      def id
        Resource::ALL
      end
    end
  end
end
