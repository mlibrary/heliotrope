module Flipflop
  class FeaturesController < ApplicationController
    include ActionController::RequestForgeryProtection
    include ActionController::Rendering
    include ActionView::Rendering
    include ActionView::Layouts

    # Allows overriding layout by inheriting from this controller.
    layout "flipflop"

    def index
      @feature_set = FeaturesPresenter.new(FeatureSet.current)
      render
    end

    class FeaturesPresenter
      include Flipflop::Engine.routes.url_helpers

      attr_reader :strategies, :grouped_features, :application_name

      def initialize(feature_set)
        @cache = {}
        @feature_set = feature_set

        @strategies = @feature_set.strategies.reject(&:hidden?)
        @grouped_features = @feature_set.features.group_by(&:group)

        app_class = Rails.application.class
        application_name = app_class.respond_to?(:module_parent_name) ?
          app_class.module_parent_name :
          app_class.parent_name

        @application_name = application_name.underscore.titleize
      end

      def grouped?
        grouped_features.keys != [nil]
      end

      def status(feature)
        cache(nil, feature) do
          status_to_sym(@feature_set.enabled?(feature.key))
        end
      end

      def strategy_status(strategy, feature)
        cache(strategy, feature) do
          status_to_sym(strategy.enabled?(feature.key))
        end
      end

      def switch_url(strategy, feature)
        feature_strategy_path(feature.key, strategy.key)
      end

      private

      def cache(strategy, feature)
        key = feature.key.to_s + (strategy ? "-" + strategy.key.to_s : "")
        return @cache[key] if @cache.has_key?(key)
        @cache[key] = yield
      end

      def status_to_sym(status)
        return :enabled if status == true
        return :disabled if status == false
      end
    end
  end
end
