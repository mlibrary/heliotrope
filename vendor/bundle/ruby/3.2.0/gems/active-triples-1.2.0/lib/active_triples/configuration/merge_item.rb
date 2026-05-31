# frozen_string_literal: true
require 'active_support/core_ext/array/wrap'

module ActiveTriples
  class Configuration
    # Configuration item which sets a value by turning the original into an array and
    # appending the given value to it.
    #
    # This enables multiple types to be set on an object, for example.
    class MergeItem < Item
      def set(value)
        object.inner_hash[key] = Array.wrap(object.inner_hash[key])
        object.inner_hash[key] |= Array.wrap(value)
      end
    end
  end
end
