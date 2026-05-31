# frozen_string_literal: true

module Checkpoint
  class Resource
    # Special class to represent any entity of any type. This is used for
    # zone-/system-wide grants or checks. It is basically so {AllOfAnyType} can
    # have an entity rather than a nil.
    #
    # Wildcards or null objects typically have somewhat strange semantics, and
    # this is no exception. It will compare as eql? and == to any object.
    class AnyEntity
      # Always returns true; this wildcard is "equal" to any object.
      # return [Boolean] true
      def eql?(*)
        true
      end

      # Always returns true; this wildcard is "equal" to any object.
      # return [Boolean] true
      def ==(*)
        true
      end
    end
  end
end
