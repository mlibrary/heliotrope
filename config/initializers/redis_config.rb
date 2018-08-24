# frozen_string_literal: true

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # We're in smart spawning mode.
    if forked
      # Re-establish redis connection
      require 'redis'
      config = YAML.safe_load(ERB.new(IO.read(Rails.root.join('config', 'redis.yml'))).result)[Rails.env].with_indifferent_access

      # The important two lines
      Redis.current.disconnect!
      Redis.current = begin
                        Redis.new(config.merge(thread_safe: true))
                      rescue StandardError
                        nil
                      end
      Resque.redis = Redis.current
      Resque.redis.namespace = "#{Hyrax.config.redis_namespace}:#{Rails.env}"
      Resque.redis&.client&.reconnect
    end
  end
else
  config = YAML.safe_load(ERB.new(IO.read(Rails.root.join('config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
  require 'redis'
  Redis.current = begin
                    Redis.new(config.merge(thread_safe: true))
                  rescue StandardError
                    nil
                  end
end
