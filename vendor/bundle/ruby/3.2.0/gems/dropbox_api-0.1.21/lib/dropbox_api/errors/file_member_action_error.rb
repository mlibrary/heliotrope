# frozen_string_literal: true
module DropboxApi::Errors
  class FileMemberActionError < BasicError
    ErrorSubtypes = {
      invalid_member: InvalidMemberError,
      no_permission: NoPermissionError,
      access_error: SharingFileAccessError,
      no_explicit_access: DropboxApi::Metadata::ParentFolderAccessInfo
    }.freeze
  end
end
