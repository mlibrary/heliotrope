# frozen_string_literal: true

module Keycard
  # A Notary is the primary entry point for authentication needs. It will
  # examine the request, session, and user-supplied credentials and provide
  # a {Result} with the results of identity verification.
  #
  # It relies on configuration to extract the correct attributes from each
  # request and to use the appropriate identity {AuthenticationMethod}. Each
  # authentication method will attempt to locate a matching account and, for
  # those methods that involve user-supplied credentials, verify that are
  # correct for that account.
  class Notary
    # Create a Notary, which authenticates requests, verifying the identity of
    # the requester and issuing an {Authentication::Result}.
    #
    # @param attributes_factory [Request::AttributesFactory] the factory to create
    #   {Request::Attributes} from the current request.
    # @param methods [Array<callable>] the list of {AuthenticationMethod}s to
    #   use, in order, each wrapped as a callable initializer. Each factory
    #   should take (attributes, session, result, **credentials) and
    #   instantiate an AuthenticationMethod with a bound account/user finder.
    def initialize(attributes_factory:, methods:)
      @attributes_factory = attributes_factory
      @methods = methods
    end

    # Create a default Notary instance, using common authenticaiton methods and
    # the default AttributesFactory that creates request attributes based on
    # the Keycard.config.access value.
    #
    # This instance assumes that there is a `User` model with class methods
    # called `authenticate_by_auth_token`, `authenticate_by_id`, and
    # `authenticate_by_user_eid`. These should find the user with the given
    # id, authorization token, and EID/username. This is the order of
    # precedence, as well, corresponding to the following {AuthenticationMethod}s:
    #
    # 1. {Keycard::Authentication::AuthToken}
    # 2. {Keycard::Authentication::SessionUserId}
    # 3. {Keycard::Authentication::UserEid}
    #
    # @return [Keycard::Notary] a default Notary instance, bound to conventional
    #   authentication methods on a User class.
    def self.default
      new(
        attributes_factory: Keycard::Request::AttributesFactory.new,
        methods: [
          Keycard::Authentication::AuthToken.bind_class_method(:User, :authenticate_by_auth_token),
          Keycard::Authentication::SessionUserId.bind_class_method(:User, :authenticate_by_id),
          Keycard::Authentication::UserEid.bind_class_method(:User, :authenticate_by_user_eid)
        ]
      )
    end

    # Authenticate a request, giving a Result of the result.
    #
    # @param request [Rack::Request] the active request, used to extract attributes
    # @param session [Session] the active session, to be inspected with #[]
    # @return [Authentication::Result] the result of this authentication
    def authenticate(request, session, **credentials)
      attributes = attributes_factory.for(request)
      Authentication::Result.new.tap do |result|
        methods.find do |factory|
          factory.call(attributes, session, result, **credentials).apply
        end
      end
    end

    # Bypass normal authentication and create a Result for the given
    # user/account. This would typically only be used in development or other
    # administrative scenarios where it is appropriate to allow impersonation.
    def waive(account)
      Authentication::Result.new.tap do |result|
        result.succeeded(account, "Administrative waiver for #{account}")
      end
    end

    # Issue an unconditional rejection Result. This is useful for a logout
    # workflow, where authenticating again yield a passing result. The
    # notion here is that the rejection would be cached just like any other
    # result, rather than simply clearing it for the request.
    #
    # A logout would typically be followed by an immediate redirect, but this
    # is a provision to ensure that the current request stays unauthenticated.
    #
    # @see {Keycard::ControllerMethods#logout} for how this is used in the
    #   context of the state of the current request.
    def reject
      Authentication::Result.new.tap do |result|
        result.failed("Authentication rejected; session terminated")
      end
    end

    private

    attr_reader :attributes_factory
    attr_reader :methods
  end
end
