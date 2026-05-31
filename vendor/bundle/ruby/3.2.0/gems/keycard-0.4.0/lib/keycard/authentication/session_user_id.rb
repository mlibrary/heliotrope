# frozen_string_literal: true

module Keycard
  module Authentication
    # Identity verification based on a user_id present in the session.
    #
    # A user_id in the session would typically be placed there after some other
    # login process, after which it is sufficient to authenticate the session.
    # The finder, then, takes only one parameter, the ID as on the account's #id
    # property.
    class SessionUserId < Method
      def apply
        if user_id.nil?
          skipped("No user_id found in session")
        elsif (account = finder.call(user_id))
          succeeded(account, "Account found for user_id '#{user_id}' in session")
        else
          failed("Account not found for user_id '#{user_id}' in session")
        end
      end

      private

      def user_id
        session[:user_id]
      end
    end
  end
end
