# frozen_string_literal: true
module DropboxApi::Errors
  class ListFolderError < BasicError
    ErrorSubtypes = {
      path: LookupError
    }.freeze
  end
end
