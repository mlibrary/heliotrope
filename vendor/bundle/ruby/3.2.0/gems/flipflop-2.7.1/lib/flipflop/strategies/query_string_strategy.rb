module Flipflop
  module Strategies
    class QueryStringStrategy < AbstractStrategy
      class << self
        def default_description
          "Interprets query string parameters as features."
        end
      end

      def initialize(**options)
        @prefix = options.delete(:prefix).to_s.freeze
        super(**options)
      end

      def enabled?(feature)
        return unless request?
        return unless request.params.has_key?(param_key(feature))
        request.params[param_key(feature)] != "0"
      end

      protected

      def param_key(feature)
        @prefix + feature.to_s
      end
    end
  end
end
