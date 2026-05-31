# frozen_string_literal: true
module DropboxApi::Errors
  class ListFolderContinueError < BasicError
    ErrorSubtypes = {
      path: WriteError,
      reset: InvalidCursorError
    }.freeze
  end
end
