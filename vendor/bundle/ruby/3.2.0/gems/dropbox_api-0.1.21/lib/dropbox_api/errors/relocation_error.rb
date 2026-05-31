# frozen_string_literal: true
module DropboxApi::Errors
  class RelocationError < BasicError
    ErrorSubtypes = {
      from_lookup: LookupError,
      from_write: WriteError,
      to: WriteError,
      cant_copy_shared_folder: CantCopySharedFolderError,
      cant_nest_shared_folder: CantNestSharedFolderError,
      cant_move_folder_into_itself: CantMoveFolderIntoItselfError,
      too_many_files: TooManyFilesError
    }.freeze
  end
end
