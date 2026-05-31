# frozen_string_literal: true
module Valkyrie::Persistence
  class OptimisticLockToken
    attr_reader :adapter_id, :token

    # @param [Valkyrie::ID] adapter_id
    # @param [String, Integer] token for the adapter
    def initialize(adapter_id:, token:)
      @adapter_id = adapter_id
      @token = token
    end

    # Serializing lock tokens makes them easy to cast to strings and back.
    # Primary use case is for embedding one in a form as a hidden field
    def serialize
      "lock_token:#{adapter_id}:#{token}"
    end
    alias to_s serialize

    def ==(other)
      return false unless other.is_a?(self.class)
      return false unless adapter_id == other.adapter_id
      token == other.token
    end

    # Deserializing lock tokens means that we can then use the adapter id and the lock token value
    def self.deserialize(serialized_token)
      token_parts = serialized_token.to_s.split(":", 3)
      adapter_id = token_parts[1]
      token = token_parts[2]
      new(adapter_id: Valkyrie::ID.new(adapter_id), token: token)
    end
  end
end
