# frozen_string_literal: true
module DropboxApi::Errors
  class UploadSessionFinishError < BasicError
    ErrorSubtypes = {
      lookup_failed: UploadSessionLookupError,
      path: WriteError,
      too_many_shared_folder_targets: TooManySharedFolderTargetsError
    }.freeze
  end
end
