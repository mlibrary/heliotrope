# frozen_string_literal: true
module DropboxApi::Errors
  class CreateFolderError < BasicError
    ErrorSubtypes = {
      path: WriteError
    }.freeze
  end
end
