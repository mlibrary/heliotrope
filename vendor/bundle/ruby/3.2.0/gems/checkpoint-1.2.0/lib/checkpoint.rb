# frozen_string_literal: true

require "checkpoint/version"

require "sequel"
require "ettin"

# All of the Checkpoint components are contained within this top-level module.
module Checkpoint
  # An error raised if there is no callable identifier on an entity when
  # attempting to convert it to a resource.
  class NoIdentifierError < StandardError; end
end

require "checkpoint/agent"
require "checkpoint/credential"
require "checkpoint/resource"
require "checkpoint/authority"
require "checkpoint/query"
require "checkpoint/railtie" if defined?(Rails)
