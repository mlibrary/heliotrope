require "digest/md5"

module Flipflop
  module Strategies
    class OptionsHasher
      def initialize(value)
        @hasher = Digest::MD5.new
        @value = value
      end

      def generate
        @hasher << begin
          Marshal.dump(@value)
        rescue TypeError
          @value.object_id.to_s
        end
        @hasher.hexdigest
      end
    end
  end
end
