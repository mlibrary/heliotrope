# frozen_string_literal: true
module DropboxApi::Errors
  class UploadSessionLookupError < BasicError
    ErrorSubtypes = {
      not_found: NotFoundError,
      incorrect_offset: UploadSessionOffsetError,
      closed: CursorClosedError,
      not_closed: CursorNotClosedError
    }.freeze
  end
end
