# frozen_string_literal: true

require 'spec_helper'

require 'simple_solr_client'

# RSpec::Mocks::MockExpectationError: An expectation of `:info` was set on `nil`.
# To allow expectations on `nil` and suppress this message,
# set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `true`.
# To disallow expectations on `nil`,
# set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `false`
RSpec::Mocks.configuration.allow_message_expectations_on_nil = false

RSpec.configure do |config|
end
