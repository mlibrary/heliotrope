# frozen_string_literal: true
module ActiveTriples
  class Configuration
    ## Returns a configuration item appropriate for a given configuration property.
    class ItemFactory
      # @return [MergeItem, Item]
      def new(object, name)
        if merge_configs.include?(name)
          merge_item.new(object, name)
        else
          item.new(object, name)
        end
      end

      def merge_item
        MergeItem
      end

      def item
        Item
      end

      def merge_configs
        [:type]
      end
    end
  end
end
