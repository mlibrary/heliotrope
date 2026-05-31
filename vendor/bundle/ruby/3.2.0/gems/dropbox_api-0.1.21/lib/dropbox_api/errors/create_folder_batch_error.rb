# frozen_string_literal: true
module DropboxApi::Errors
  class CreateFolderBatchError < BasicError
    ErrorSubtypes = {
      too_many_files: TooManyFilesError
    }.freeze
  end
end
