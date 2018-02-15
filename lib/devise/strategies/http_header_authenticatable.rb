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
        user_key = remote_user(request.headers)
        if user_key.present?
          Rails.logger.debug "[AUTHN] HttpHeaderAuthenticatable#authenticate! succeeded: _#{user_key}_"
          user = User.find_by(user_key: user_key)
          if user.nil?
            Rails.logger.debug '[AUTHN] HttpHeaderAuthenticatable#authenticate! create.'
            user = User.create(user_key: user_key)
            user.populate_attributes
          else
            Rails.logger.debug '[AUTHN] HttpHeaderAuthenticatable#authenticate! found.'
          end
          success!(user)
        else
          Rails.logger.debug "[AUTHN] HttpHeaderAuthenticatable#authenticate! failed: _#{user_key}_"
          fail!
        end
      end
    end
  end
end

Warden::Strategies.add(:http_header_authenticatable, Devise::Strategies::HttpHeaderAuthenticatable)
