# frozen_string_literal: true
module DropboxApi::Errors
  class WriteConflictError < BasicError
    ErrorSubtypes = {
      file: FileConflictError,
      folder: FolderConflictError,
      file_ancestor: FileAncestorConflictError
    }
  end
end
