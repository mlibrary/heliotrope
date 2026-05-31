# frozen_string_literal: true
module DropboxApi::Errors
  class UploadWriteFailedError < BasicError
    ErrorSubtypes = {
      reason: WriteError
    }.freeze
  end
end
