# frozen_string_literal: true

module Keycard
  module Authentication
    # An abstract identity authentication method. Subclasses will inspect the
    # attributes and session for a request, attempting to match an account, and
    # recording the results on a {Result}.
    #
    # The general operation is that each authentication method will have its
    # {#apply} method called. It should examine the attributes, session, or
    # credentials, and decide whether the required information is present. Then:
    #
    # 1. If the method is not applicable, call {#skipped} with a message naming
    #    the authentication method and why it was not applicable.
    # 2. If the method is applicable, call the finder to attempt to locate the
    #    user/account and verify the method-specific information. For example,
    #    some methods will trust a username attribute that arrived by way of
    #    a reverse proxy, and the finder will only need to verify that a user
    #    exists with the given username. Other methods will need to verify that
    #    a token or password supplied hashes to the correct value.
    # 3. Depending on whether a user/account is identified and authenticated,
    #    call {#succeeded} with the account and a message, or {#failed} with
    #    a message.
    #
    # Each of the status methods appends to a result for diagnostic or audit
    # purposes and affects whether the chain of authentication should continue or
    # be terminated. If a authentication method is skipped, the next one will be
    # attempted. If it succeeds, or fails, the chain will be terminated. If it
    # succeeds, the identity attributes will be assigned to the account, and it
    # will be set as the account on the result.
    #
    # For integration with larger-scale configuration (like how request
    # attributes should be extracted and which authentication methods should be
    # used, in what order), see {Keycard::Notary}.
    #
    # For stateful integration with controllers (like the notions of a "current
    # user" and logging in and out), see {Keycard::ControllerMethods}.
    class Method
      def initialize(attributes:, session:, result:, finder:, **credentials)
        @attributes = attributes
        @session = session
        @result = result
        @finder = finder
        @credentials = credentials
      end

      # Bind a finder callable and yield a factory lambda to create a
      # Verification with all of the other parameters. This allows for
      # configuring a prototype at the system level and applying items that vary
      # per request more conveniently.
      def self.bind(finder)
        lambda do |attributes, session, result, **credentials|
          new(
            attributes: attributes,
            session: session,
            result: result,
            finder: finder,
            credentials: credentials
          )
        end
      end

      # Bind a class method as a finder. This is more convenient form than
      # {::bind} because it uses a {Keycard::ReloadableProxy}, making it easier
      # to work with finder methods on ActiveRecord models, which are reloaded in
      # development on each change, without restarting the server.
      def self.bind_class_method(finder_class, method)
        bind(ReloadableProxy.new(finder_class, method))
      end

      # Attempt to apply this authentication method and record the status on the
      # result.
      def apply
        skipped("Base Verification is always skipped; it should not be used directly.")
      end

      private

      def skipped(message)
        result.skipped(message)
      end

      def succeeded(account, message, csrf_safe: false)
        account.identity = attributes.identity
        result.succeeded(account, message, csrf_safe: csrf_safe)
      end

      def failed(message)
        result.failed(message)
      end

      attr_reader :attributes
      attr_reader :session
      attr_reader :result
      attr_reader :finder
      attr_reader :credentials
    end
  end
end
