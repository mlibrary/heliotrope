# frozen_string_literal: true
module DropboxApi::Errors
  class UploadSessionOffsetError < BasicError
    def initialize(message, metadata)
      message = "#{message}, correct offset: #{metadata['correct_offset']}"
      super message, metadata
    end
  end
end
