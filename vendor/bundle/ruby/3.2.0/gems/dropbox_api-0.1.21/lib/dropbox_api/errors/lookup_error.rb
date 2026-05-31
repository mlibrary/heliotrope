# frozen_string_literal: true
module DropboxApi::Errors
  class LookupError < BasicError
    ErrorSubtypes = {
      malformed_path: MalformedPathError,
      not_found: NotFoundError,
      not_file: NotFileError,
      not_folder: NotFolderError,
      restricted_content: RestrictedContentError
    }.freeze
  end
end
