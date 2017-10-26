# frozen_string_literal: true

# default spec helper
require 'spec_helper'

# RSpec::Mocks::MockExpectationError: An expectation of `:info` was set on `nil`.
# To allow expectations on `nil` and suppress this message,
# set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `true`.
# To disallow expectations on `nil`,
# set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `false`
RSpec::Mocks.configuration.allow_message_expectations_on_nil = false

# ActiveSupport
require 'active_support'
# present?, blank?, and other stuff...
require 'active_support/core_ext'
# autoload
require 'active_support/dependencies'
# lib
ActiveSupport::Dependencies.autoload_paths << File.expand_path("../../../lib", __FILE__)

# Use this setup block to configure all options available in EPub.
EPub.configure do |config|
  # config.logger = Rails.logger
  config.root = "../tmp/lib/spec/epubs"
end
