# frozen_string_literal: true
module DropboxApi::Errors
  class AddFileMemberError < BasicError
    ErrorSubtypes = {
      user_error: SharingUserError,
      access_error: SharingFileAccessError,
      rate_limit: RateLimitError,
      invalid_comment: InvalidCommentError
    }.freeze
  end
end
