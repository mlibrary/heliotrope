# frozen_string_literal: true

module Hyrax
  module ApplicationCable
    class Connection < ActionCable::Connection::Base
      identified_by :current_user, :session_id

      def connect
        self.current_user = find_verified_user
      end

      # Heliotrope override
      # For some annoying auto-loading reason ActionCable is loading Hyrax's
      # ApplicationCable::Connection and ignoring ours. Taking this code out of Hyrax, adding it here
      # and adding our session_id method to it works.
      def session_id
        Rails.logger.debug { "Hyrax::ActionCable::Connection session is: #{session}" }
        Rails.logger.debug { "Hyrax::ActionCable::Connection session_id is: #{session['session_id']}" }
        session['session_id']
      end

      private

        def find_verified_user
          user = ::User.find_by(id: user_id)
          if user
            user
          else
            reject_unauthorized_connection
          end
        end

        def user_id
          session['warden.user.user.key'][0][0]
        rescue NoMethodError
          nil
        end

        def session
          cookies.encrypted[Rails.application.config.session_options[:key]]
        end
    end
  end
end
