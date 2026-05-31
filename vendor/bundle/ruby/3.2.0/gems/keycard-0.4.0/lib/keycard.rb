# frozen_string_literal: true

require "keycard/version"
require "sequel"
require "ostruct"

# All of the Keycard components are contained within this top-level module.
module Keycard
  class AuthenticationRequired < StandardError; end

  class AuthenticationFailed < StandardError; end

  def self.config
    @config ||= OpenStruct.new(
      access: :direct
    )
  end
end

require "keycard/digest_key"
require "keycard/db"
require "keycard/railtie" if defined?(Rails)
require "keycard/institution_finder"
require "keycard/request"
require "keycard/token"

require "keycard/notary"

require "keycard/authentication/method"
require "keycard/authentication/result"

require "keycard/authentication/auth_token"
require "keycard/authentication/session_user_id"
require "keycard/authentication/user_eid"

require "keycard/reloadable_proxy"
require "keycard/controller_methods"
