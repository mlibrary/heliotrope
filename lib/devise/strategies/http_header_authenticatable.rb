# frozen_string_literal: true

module Devise
  module Strategies
    class HttpHeaderAuthenticatable < ::Devise::Strategies::Base
      include Behaviors::HttpHeaderAuthenticatableBehavior

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
          user = nil
          if Rails.configuration.create_user_on_login
            debug_log "New user: '#{user_key}'"
            user = User.new(user_key: user_key)
            user.populate_attributes
          else
            debug_log "Did not find and will not create: '#{user_key}'"
          end
          user
        end

        def debug_log(msg)
          Rails.logger.debug "[AUTHN] HttpHeaderAuthenticatable -- #{msg}"
        end
    end
  end
end

Warden::Strategies.add(:http_header_authenticatable, Devise::Strategies::HttpHeaderAuthenticatable)
