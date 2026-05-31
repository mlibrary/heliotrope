# frozen_string_literal: true

# Injects behaviors into User model so that it will work with
# Blacklight Access Controls.  By default, this module assumes
# you are using the User model created by Blacklight, which uses
# Devise.
# To integrate your own User implementation into Blacklight,
# override this module or define your own User model in
# app/models/user.rb within your Blacklight application.

module Blacklight
  module AccessControls
    module User
      extend ActiveSupport::Concern

      # This method should display the unique identifier for
      # this user as defined by devise.  The unique identifier
      # is what access controls will be enforced against.
      def user_key
        send(Devise.authentication_keys.first)
      end
    end
  end
end
