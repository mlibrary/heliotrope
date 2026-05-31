require "active_support/concern"
require "active_support/core_ext/hash/slice"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/inflector"

require "flipflop/configurable"
require "flipflop/facade"
require "flipflop/feature_cache"
require "flipflop/feature_definition"
require "flipflop/feature_loader"
require "flipflop/feature_set"
require "flipflop/group_definition"

require "flipflop/strategies/abstract_strategy"
require "flipflop/strategies/options_hasher"

require "flipflop/strategies/active_record_strategy"
require "flipflop/strategies/cookie_strategy"
require "flipflop/strategies/default_strategy"
require "flipflop/strategies/lambda_strategy"
require "flipflop/strategies/query_string_strategy"
require "flipflop/strategies/redis_strategy"
require "flipflop/strategies/session_strategy"
require "flipflop/strategies/sequel_strategy"
require "flipflop/strategies/test_strategy"

require "flipflop/engine" if defined?(Rails)

module Flipflop
  extend Facade
end
