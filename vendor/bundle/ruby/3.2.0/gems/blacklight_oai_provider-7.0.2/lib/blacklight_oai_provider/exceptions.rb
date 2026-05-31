module BlacklightOaiProvider
  module Exceptions
    class MissingTimestamp < StandardError
      def initialize(msg = "Missing required timestamp field")
        super
      end
    end
  end
end
