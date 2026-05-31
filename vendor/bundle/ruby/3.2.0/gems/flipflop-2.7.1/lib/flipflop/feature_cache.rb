module Flipflop
  class FeatureCache
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) if FeatureCache.current.enabled?

        FeatureCache.current.enable!
        response = @app.call(env)
        response[2] = Rack::BodyProxy.new(response[2]) do
          FeatureCache.current.disable!
        end
        response
      rescue Exception => err
        FeatureCache.current.disable!
        raise err
      end
    end

    class << self
      def current
        Thread.current.thread_variable_get(:flipflop_cache) or
        Thread.current.thread_variable_set(:flipflop_cache, new)
      end

      private :new
    end

    def initialize
      @enabled = false
      @cache = {}
    end

    def enabled?
      @enabled
    end

    def clear!
      @cache.clear
    end

    def enable!
      @enabled = true
    end

    def disable!
      @enabled = false
      @cache.clear
    end

    def fetch(key)
      if @enabled
        @cache.fetch(key) do
          @cache[key] = yield
        end
      else
        yield
      end
    end
  end
end
