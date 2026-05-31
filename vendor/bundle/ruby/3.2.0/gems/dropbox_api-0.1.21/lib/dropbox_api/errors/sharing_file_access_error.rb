# frozen_string_literal: true
module DropboxApi::Errors
  class SharingFileAccessError < BasicError
    ErrorSubtypes = {
      no_permission: NoPermissionError,
      invalid_file: InvalidFileError,
      is_folder: IsFolderError,
      inside_public_folder: InsidePublicFolderError,
      inside_osx_package: InsideOsxPackageError
    }.freeze
  end
end
