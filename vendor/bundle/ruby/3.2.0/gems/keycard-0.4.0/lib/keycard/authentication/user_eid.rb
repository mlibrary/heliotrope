# frozen_string_literal: true

module Keycard
  module Authentication
    # Identity verification based on the user EID request attribute.
    #
    # The EID will typically be present in single sign-on scenarios, where
    # there is a proxy in place to set secure headers. The finder is expected
    # to take one paramter, the user_eid itself.
    class UserEid < Method
      def apply
        if user_eid.nil?
          skipped("No user_eid found in request attributes")
        elsif (account = finder.call(user_eid))
          succeeded(account, "Account found for user_eid '#{user_eid}'")
        else
          failed("Account not found for user_eid '#{user_eid}'")
        end
      end

      private

      def user_eid
        attributes.user_eid
      end
    end
  end
end
