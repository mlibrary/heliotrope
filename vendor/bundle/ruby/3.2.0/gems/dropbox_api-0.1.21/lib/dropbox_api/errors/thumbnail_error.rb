# frozen_string_literal: true
module DropboxApi::Errors
  class ThumbnailError < BasicError
    ErrorSubtypes = {
      path: LookupError,
      unsupported_extension: UnsupportedExtensionError,
      unsupported_image: UnsupportedImageError,
      conversion_error: ConversionError
    }.freeze
  end
end
