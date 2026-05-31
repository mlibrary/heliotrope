# frozen_string_literal: true
module DropboxApi::Errors
  class SaveUrlError < BasicError
    ErrorSubtypes = {
      path: WriteError,
      download_failed: DownloadFailedError,
      invalid_url: InvalidUrlError,
      not_found: NotFoundError
    }.freeze
  end
end
