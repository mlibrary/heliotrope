# frozen_string_literal: true

# A container module for classes related to processing HTTP/Rack requests
module Keycard::Request
end

require_relative "request/attributes"
require_relative "request/cosign_attributes"
require_relative "request/direct_attributes"
require_relative "request/proxied_attributes"
require_relative "request/shibboleth_attributes"
require_relative "request/attributes_factory"
