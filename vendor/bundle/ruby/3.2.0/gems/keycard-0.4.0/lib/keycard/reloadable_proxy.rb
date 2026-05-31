# frozen_string_literal: true

module Keycard
  # A proxy for class methods, as for authentication methods on User/Account
  # models. This is useful primarily during development mode, where binding
  # a finder into a Verfication factory can break because of code reloading.
  #
  # For example, something like this would fail across requests where the User
  # model is saved (in development):
  # `AuthToken.bind(User.public_method(:authenticate_by_auth_token))`.
  #
  # Instead, you can bind to a class method with a proxy that will catch the
  # error from Rails thrown when using a stale reference, replace the target
  # method, and retry the call transparently.
  #
  # @example
  #   callable = ReloadableProxy.new(:User, :authenticate_by_auth_token)
  class ReloadableProxy
    attr_reader :classname, :methodname, :target

    def initialize(classname, methodname)
      @classname = classname
      @methodname = methodname
      lookup
    end

    # Call the proxied class method, looking it up again if the class has been
    # reloaded (as signified byt he ArgumentError Rails raises).
    def call(*args)
      target.call(*args)
    rescue ArgumentError
      lookup
      target.call(*args)
    end

    def lookup
      @target = Object.const_get(classname).method(methodname)
    end
  end
end
