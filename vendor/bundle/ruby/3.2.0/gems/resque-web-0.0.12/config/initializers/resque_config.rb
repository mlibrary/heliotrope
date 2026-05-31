require 'resque'

# Previously, this initializer always set Resque.redis, and defaulted
# to '127.0.0.1:6379' if RAILS_RESQUE_REDIS was not set.
if ENV['RAILS_RESQUE_REDIS'].present?
  Resque.redis = ENV['RAILS_RESQUE_REDIS']
end

# Have to do this to accept password because resque does not support
# setting it in the string.
redis_password = ENV['RAILS_RESQUE_REDIS_PASSWORD']
if redis_password.present?
  opts = Resque.redis.client.options
  redis = Redis.new(opts.merge(password: redis_password))
  Resque.redis = redis
end
