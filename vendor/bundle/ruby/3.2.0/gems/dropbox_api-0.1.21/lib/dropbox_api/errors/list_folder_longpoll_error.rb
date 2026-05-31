# frozen_string_literal: true
module DropboxApi::Errors
  class ListFolderLongpollError < BasicError
    ErrorSubtypes = {
      reset: InvalidCursorError
    }.freeze
  end
end
