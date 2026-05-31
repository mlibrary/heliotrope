# frozen_string_literal: true

module Checkpoint
  module DB
    # A helper for building placeholder variable names from items in a list and
    # providing a corresponding hash of values. A prefix with some mnemonic
    # corresponding to the column is recommended. For example, if the column is
    # `agent_token`, using the prefix `at` will yield `$at_0`, `$at_1`, etc. for
    # an IN clause.
    class Params
      attr_reader :items, :prefix

      def initialize(items, prefix)
        @items = [items].flatten
        @prefix = prefix
      end

      def placeholders
        0.upto(items.size - 1).map do |i|
          :"$#{prefix}_#{i}"
        end
      end

      def values
        items.map.with_index do |item, i|
          value = if item.respond_to?(:sql_value)
            item.sql_value
          else
            item.to_s
          end
          [:"#{prefix}_#{i}", value]
        end
      end
    end
  end
end
