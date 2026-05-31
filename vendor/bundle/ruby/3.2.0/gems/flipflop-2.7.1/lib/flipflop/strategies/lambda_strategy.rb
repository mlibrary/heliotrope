module Flipflop
  module Strategies
    class LambdaStrategy < AbstractStrategy
      class << self
        def default_description
          "Resolves feature settings with custom code."
        end
      end

      def initialize(**options)
        @lambda = (options.delete(:lambda) || ->(*) { }).freeze
        super(**options)
        if @lambda.arity.abs != 1
          raise StrategyError.new(name, "has lambda with arity #{@lambda.arity}, expected 1 or -1")
        end
      end

      def enabled?(feature)
        result = instance_exec(feature, &@lambda)
        return result if result.nil? or result == !!result
        raise StrategyError.new(name, "returned invalid result #{result.inspect} for feature '#{feature}'")
      end
    end
  end
end
