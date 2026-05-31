# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class Download < DropboxApi::Endpoints::ContentDownload
    Method      = :post
    Path        = '/2/files/download'
    ResultType  = DropboxApi::Metadata::File
    ErrorType   = DropboxApi::Errors::DownloadError

    # Download a file from a user's Dropbox.
    #
    # @param path [String] The path of the file to download.
    add_endpoint :download do |path, &block|
      perform_request({path: path}, &block)
    end
  end
end
