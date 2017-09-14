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
# app services (e_pubs_*)
ActiveSupport::Dependencies.autoload_paths <<  File.expand_path("../../../app/services", __FILE__)
# lib
ActiveSupport::Dependencies.autoload_paths <<  File.expand_path("../../../lib", __FILE__)
ActiveSupport::Dependencies.autoload_paths <<  File.expand_path("../../../lib/e_pub", __FILE__)
