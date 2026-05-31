# frozen_string_literal: true

module Keycard
  module Authentication
    # A Result is the central point of information about an authentication
    # attempt. It logs the authentication methods attempted with their statuses
    # and reports the overall status. When authentication is successful, it holds
    # the user/account that was verified.
    class Result
      attr_reader :account
      attr_reader :log

      def initialize
        @account = nil
        @log = []
        @failed = false
        @csrf_safe = false
      end

      # Has this authentication completed successfully?
      def authenticated?
        !account.nil?
      end

      # Was there a failure for an attempted authentication method?
      def failed?
        @failed
      end

      # Does a completed verification protect from Cross-Site Request Forgery?
      #
      # This should be true in cases where the client presents authentication
      # that is not automatic, like an authentication token, rather than
      # automatic credentials like cookies or proxy-applied headers.
      def csrf_safe?
        @csrf_safe
      end

      # Log that the authentication method was not applicable; continue the chain.
      #
      # @param message [String] a message about why the authentication method was skipped
      # @return [Boolean] false, indicating that the authentication method was inconclusive
      def skipped(message)
        log << "[SKIPPED] #{message}"
        false
      end

      # Log that the authentication method failed; terminate the chain.
      #
      # @param message [String] a message about how the authentication method failed
      # @return [Boolean] true, indicating that further authentication should not occur
      def failed(message)
        log << "[FAILURE] #{message}"
        @failed = true
      end

      # Log that the authentication method succeeded; terminate the chain.
      #
      # @param account [User|Account] Object/model representing the authenticated account
      # @param message [String] a message about how the authentication method succeeded
      # @param csrf_safe [Boolean] set to true if this authentication method precludes
      #   Cross-Site Request Forgery, as with a non-cookie token sent with the request
      # @return [Boolean] true, indicating that further authentication should not occur
      def succeeded(account, message, csrf_safe: false)
        @account = account
        @csrf_safe ||= csrf_safe
        log << "[SUCCESS] #{message}"
        true
      end
    end
  end
end
