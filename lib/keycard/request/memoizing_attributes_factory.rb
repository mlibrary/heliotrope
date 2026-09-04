# frozen_string_literal: true

require_relative "memoized_attributes"

module Keycard
  module Request
    # A Keycard::Request::AttributesFactory that hands back Attributes which
    # only consult their finders once.
    #
    # Extending the instance rather than prepending MemoizedAttributes onto
    # Keycard::Request::Attributes keeps the change scoped to the attributes
    # this application builds, and leaves anything constructing Keycard
    # attributes directly with the gem's behaviour.
    class MemoizingAttributesFactory < AttributesFactory
      def for(request)
        super.extend(MemoizedAttributes)
      end
    end
  end
end
