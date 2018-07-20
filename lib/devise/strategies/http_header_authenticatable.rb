# frozen_string_literal: true

module Devise
  module Strategies
    class HttpHeaderAuthenticatable < ::Devise::Strategies::Base
      include Devise::Behaviors::HttpHeaderAuthenticatableBehavior

      # Called if the user doesn't already have a rails session cookie.
      def valid?
        valid_user?(request.headers)
      end

      # Called to authenticate user.
      def authenticate!
        user = nil
        user = existing_user || new_user if user_key.present?
        if user
          success!(user)
        else
          debug_log "Failed (user_key blank)"
          fail!
        end
      end

      # Override and set to false for things like OmniAuth that technically
      # run through Authentication (user_set) very often, which would normally
      # reset CSRF data in the session
      def clean_up_csrf?
        false
      end

      private

        def user_key
          remote_user(request.headers)
        end

        def existing_user
          user = User.find_by(user_key: user_key)
          debug_log "Found: '#{user_key}'" if user
          user
        end

        def new_user
          user =
            if Rails.configuration.create_user_on_login
              debug_log "New user: '#{user_key}'"
              User.new(user_key: user_key)
            else
              debug_log "Guest user: '#{user_key}'"
              User.guest(user_key: user_key)
            end
          user.populate_attributes
          user
        end

        def debug_log(msg)
          Rails.logger.debug "[AUTHN] HttpHeaderAuthenticatable -- #{msg}"
        end
    end
  end
end

Warden::Strategies.add(:http_header_authenticatable, Devise::Strategies::HttpHeaderAuthenticatable)
