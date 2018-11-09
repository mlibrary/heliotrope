# frozen_string_literal: true

require 'devise/strategies/keycard_authenticatable'
module Devise
  module Models
    # Mix-in to expose the Keycard identity attributes on the model object.
    # They are set by the strategy once the request attributes are resolved,
    # meaning that an authenticated user will carry its identification with it.
    # This avoids having to resolve the request attributes again somewhere in
    # the controller context.
    module KeycardAuthenticatable
      extend ActiveSupport::Concern

      included do
        attr_writer :identity
        attr_writer :request_attributes
      end

      def identity
        @identity ||= {}
      end

      def request_attributes
        @request_attributes ||= {}
      end
    end
  end
end
