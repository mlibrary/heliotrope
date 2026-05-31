# frozen_string_literal: true
module DropboxApi::Errors
  class SharedFolderAccessError < BasicError
    ErrorSubtypes = {
      invalid_id: InvalidIdError,
      not_a_member: NotAMemberError,
      email_unverified: EmailUnverifiedError,
      unmounted: UnmountedError
    }.freeze
  end
end
