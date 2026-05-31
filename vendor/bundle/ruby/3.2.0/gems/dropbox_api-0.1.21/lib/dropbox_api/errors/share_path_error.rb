# frozen_string_literal: true
module DropboxApi::Errors
  class SharePathError < BasicError
    ErrorSubtypes = {
      is_file: IsFileError,
      inside_shared_folder: InsideSharedFolderError,
      contains_shared_folder: ContainsSharedFolderError,
      is_app_folder: IsAppFolderError,
      inside_app_folder: InsideAppFolderError,
      is_public_folder: IsPublicFolderError,
      inside_public_folder: InsidePublicFolderError,
      already_shared: AlreadySharedError,
      invalid_path: InvalidPathError,
      is_osx_package: IsOsxPackageError,
      inside_osx_package: InsideOsxPackageError,
    }.freeze
  end
end
