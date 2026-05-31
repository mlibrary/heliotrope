# frozen_string_literal: true
module DropboxApi::Errors
  class PreviewError < BasicError
    ErrorSubtypes = {
      path: LookupError,
      in_progress: InProgressError,
      unsupported_extension: UnsupportedExtensionError,
      unsupported_content: UnsupportedContentError
    }.freeze
  end
end
