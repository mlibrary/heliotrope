# frozen_string_literal: true

module Devise
  module Strategies
    # Devise strategy for authenticating _individual_ users who are logging in
    # to the application, not just authenticating for reading purposes. This
    # uses Keycard to resolve the user EID.
    class KeycardAuthenticatable < ::Devise::Strategies::Base
      # NOTE: This is a workaround...
      # Two elements would make for a more pleasant experience and implementation:
      # 1. Automatically logging in users who have an SP/SSO session
      # 2. Terminating the SP/SSO session for effective logout and/or user change
      #
      # Meanwhile...
      # The log_me_in flag is used to signal that this strategy can be used.
      # It is to indicate that the user has affirmatively acted to log in via
      # Shibboleth. Otherwise, logging out can cycle back to a protected
      # resource and the Shibboleth session will still be open, causing a new
      # app session immediately.
      #
      # Called if the user doesn't already have a rails session cookie.
      def valid?
        Rails.configuration.auto_login || session[:log_me_in]
      end

      # Look up and set the "current user" based on EID. This may be an
      # existing (persisted), new (unsaved, but saveable by the app), or guest
      # (unsaved, but will raise if save is attempted) User object.
      #
      # Called to authenticate user.
      def authenticate!
        if user_eid.present? || identity_provider.present?
          set_user!
        else
          debug_log "Passing (insufficient data in request attributes '#{request_attributes.all}')"
          pass
        end
      end

      # Override and set to false for things like OmniAuth that technically
      # run through Authentication (user_set) very often, which would normally
      # reset Cross-site request forgery (CSRF) data in the session
      def clean_up_csrf?
        false
      end

      private

        def set_user! # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          user = nil
          user ||= existing_user || new_user || guest_user if user_eid.present?
          user ||= guest_institution_user if identity_provider.present?
          if user
            user.identity = identity
            user.request_attributes = request_attributes
            debug_log "Success '#{user.request_attributes[:identity_provider]}'"
            success!(user)
          else
            debug_log "Failed (no existing user and did not make a new/guest)"
            fail!
          end
        end

        def user_eid
          identity[:user_eid]
        end

        def identity_provider
          request_attributes[:identity_provider]
        end

        def request_attributes
          @request_attributes ||= Services.request_attributes.for(request)
        end

        def identity
          @identity ||= request_attributes.identity
        end

        def user_eid_to_key
          key = user_eid.downcase
          if key.include?('@')
            # friend+hotmail.com@umich.edu
            match = /(^.+)(\+)(.+\..+)(@umich\.edu$)/.match(key)
            return key if match.blank?
            match[1] + '@' + match[3]
          else
            key + '@umich.edu'
          end
        end

        def existing_user
          User.find_by(user_key: user_eid_to_key).tap do |user|
            debug_log "Found user: '#{user_eid_to_key}'" if user
          end
        end

        def new_user
          return unless Rails.configuration.create_user_on_login
          User.new(user_key: user_eid_to_key).tap do |user|
            debug_log "New user: '#{user_eid_to_key}'" if user
          end
        end

        def guest_user
          User.guest(user_key: user_eid_to_key).tap do |user|
            debug_log "Guest user: '#{user_eid_to_key}'" if user
          end
        end

        def identity_provider_to_key
          # institution = Institution.find_by(entity_id: identity_provider)
          "guest@fulcrum.org"
        end

        def guest_institution_user
          User.guest(user_key: identity_provider_to_key).tap do |user|
            debug_log "Guest institution user: #{identity_provider}" if user
          end
        end

        def debug_log(msg)
          Rails.logger.debug { "[AUTHN] KeycardAuthenticatable -- #{msg}" }
        end
    end
  end
end

Warden::Strategies.add(:keycard_authenticatable, Devise::Strategies::KeycardAuthenticatable)
