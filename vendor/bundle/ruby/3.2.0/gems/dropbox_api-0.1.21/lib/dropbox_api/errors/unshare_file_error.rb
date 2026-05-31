# frozen_string_literal: true
module DropboxApi::Errors
  class UnshareFileError < BasicError
    ErrorSubtypes = {
      user_error: SharingUserError,
      access_error: SharingFileAccessError
    }.freeze
  end
end
