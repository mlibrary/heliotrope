# frozen_string_literal: true
module DropboxApi
  class Client
    def initialize(
      oauth_bearer = ENV['DROPBOX_OAUTH_BEARER'],
      access_token: nil,
      on_token_refreshed: nil
    )
      if access_token
        @connection_builder = ConnectionBuilder.new(
          access_token: access_token,
          on_token_refreshed: on_token_refreshed
        )
      elsif oauth_bearer
        @connection_builder = ConnectionBuilder.new(oauth_bearer)
      else
        raise ArgumentError, "Either oauth_bearer or access_token should be set"
      end
    end

    def middleware
      @connection_builder.middleware
    end

    def namespace_id=(value)
      @connection_builder.namespace_id = value
    end

    def namespace_id
      @connection_builder.namespace_id
    end

    # @!visibility private
    def self.add_endpoint(name, endpoint)
      define_method(name) do |*args, &block|
        endpoint.new(@connection_builder).send(name, *args, &block)
      end
    end
  end
end
