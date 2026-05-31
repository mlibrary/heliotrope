module Flipflop
  module Strategies
    class SequelStrategy < AbstractStrategy
      class << self
        def default_description
          "Stores features in database. Applies to all users."
        end

        def define_feature_class
          return Flipflop::Feature if defined?(Flipflop::Feature)

          model = Class.new(Sequel::Model(:flipflop_features))
          model.plugin(:timestamps, force: true, update_on_create: true)
          model.raise_on_save_failure = true

          Flipflop.const_set(:Feature, model)
        end
      end

      def initialize(**options)
        @class = options.delete(:class) || self.class.define_feature_class
        if !@class.kind_of?(Class)
          @class = ActiveSupport::Inflector.constantize(@class.to_s)
        end
        super(**options)
      end

      def switchable?
        true
      end

      def enabled?(feature)
        find(feature).try(:enabled?)
      end

      def switch!(feature, enabled)
        record = find_or_new(feature)
        record.enabled = enabled
        record.save
      end

      def clear!(feature)
        find(feature).try(:destroy)
      end

      protected

      def find_or_new(feature)
        find(feature) || @class.new(key: feature.to_s)
      end

      def find(feature)
        @class.where(key: feature.to_s).first
      end
    end
  end
end
