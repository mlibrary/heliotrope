# frozen_string_literal: true
module ActiveEncode
  module EngineAdapters
    class TestAdapter
      def initialize
        @encodes = {}
      end

      def create(input_url, options = {})
        new_encode = ActiveEncode::Base.new(input_url, options)
        new_encode.id = SecureRandom.uuid
        new_encode.state = :running
        new_encode.created_at = Time.now.utc
        new_encode.updated_at = Time.now.utc
        @encodes[new_encode.id] = new_encode
        new_encode
      end

      def find(id, _opts = {})
        new_encode = @encodes[id]
        # Update the updated_at time to simulate changes
        new_encode.updated_at = Time.now.utc
        new_encode
      end

      def cancel(id)
        new_encode = @encodes[id]
        new_encode.state = :cancelled
        new_encode.updated_at = Time.now.utc
        new_encode
      end
    end
  end
end
