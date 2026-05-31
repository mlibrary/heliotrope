# frozen_string_literal: true
module DropboxApi::Errors
  class WriteError < BasicError
    ErrorSubtypes = {
      malformed_path: MalformedPathError,
      conflict: WriteConflictError,
      no_write_permission: NoWritePermissionError,
      insufficient_space: InsufficientSpaceError,
      disallowed_name: DisallowedNameError
    }
  end
end
