# frozen_string_literal: true

module Keycard
  # Mixin for conveniences in controllers.
  #
  # These methods depend on a `notary` method in your controller that returns a
  # configured {Keycard::Notary} instance.
  module ControllerMethods
    # The default session timeout is 24 hours, in seconds.
    DEFAULT_SESSION_TIMEOUT = 60 * 60 * 24

    # Check whether the current request is authenticated as coming from a known
    # person or account.
    #
    # @return [Boolean] true if any of the {Notary}'s configured authentication
    #   methods succeeds
    def logged_in?
      authentication.authenticated?
    end

    # Retrieve the user/account to which the current request is attributed.
    #
    # @return [User/Account] the user/account that has been authenticated; nil
    #   if no one is logged in
    def current_user
      authentication.account
    end

    # Validate the session, resetting it if expired.
    #
    # This should be called as a before_action before {#authenticate!} when
    # working with session-based logins. It preserves a CSRF token, if present,
    # so login forms and the like will pass forgery protection.
    def validate_session
      csrf_token = session[:_csrf_token]
      elapsed = begin
        Time.now - Time.at(session[:timestamp] || 0)
      rescue
        session_timeout
      end
      reset_session if elapsed >= session_timeout
      session[:_csrf_token] = csrf_token
      session[:timestamp] = Time.now.to_i if session.key?(:timestamp)
    end

    # Require that some authentication method successfully identifies a user/account,
    # raising an exception if there is a failure for active credentials or no
    # applicable credentials are presented.
    #
    # @raise [AuthenticationFailed] if credentials for an attempted
    #   authentication method are incorrect
    # @raise [AuthenticationRequired] if all authentication methods are skipped
    #   and authentication could not be attempted
    # @return nil
    def authenticate!
      raise AuthenticationFailed if authentication.failed?
      raise AuthenticationRequired unless authentication.authenticated?
    end

    # Attempt to authenticate, optionally with user-supplied credentials, and
    # establish a session.
    #
    # @param credentials [Hash|kwargs] user-supplied credentials that will be
    #   passed to each authentication method
    # @return [Boolean] whether the login attempt was successful
    def login(**credentials)
      authentication(**credentials).authenticated?.tap do |success|
        setup_session if success
      end
    end

    # Log an account in without checking any credentials, starting a session.
    #
    # @param account [User|Account] the user/account object to consider current;
    #   must have an #id property.
    def auto_login(account)
      request.env["keycard.authentication"] = notary.waive(account)
      setup_session
    end

    # Clear authentication status and terminate any open session.
    def logout
      request.env["keycard.authentication"] = notary.reject
      reset_session
    end

    private

    def authentication(**credentials)
      request.env["keycard.authentication"] ||=
        notary.authenticate(request, session, **credentials)
    end

    # The session timeout, in seconds. Sessions will be cleared before any
    # further authentication unless there is a timestamp younger than this many
    # seconds old. The default is 24 hours.
    #
    # @return [Integer] session timeout, in seconds
    def session_timeout
      DEFAULT_SESSION_TIMEOUT
    end

    def setup_session
      return_url = session[:return_to]
      reset_session
      session[:return_to] = return_url
      session[:user_id] = current_user.id
      session[:timestamp] = Time.now.to_i
    end
  end
end
