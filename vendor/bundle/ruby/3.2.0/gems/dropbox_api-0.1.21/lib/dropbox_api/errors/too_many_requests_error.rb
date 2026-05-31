# frozen_string_literal: true
module DropboxApi::Errors
  class TooManyRequestsError < BasicError; end
  class TooManyWriteOperationsError < TooManyRequestsError; end

  class TooManyRequestsError
    attr_accessor :retry_after

    def self.build(message, metadata)
      subtype, metadata = find_subtype metadata

      subtype.new(message, metadata)
    end

    ErrorSubtypes = {
      too_many_requests: TooManyRequestsError,
      too_many_write_operations: TooManyWriteOperationsError
    }
  end
end
