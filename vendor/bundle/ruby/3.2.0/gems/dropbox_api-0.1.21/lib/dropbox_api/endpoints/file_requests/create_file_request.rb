# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class CreateFileRequest < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/file_requests/create'
    ResultType  = DropboxApi::Metadata::FileRequest
    ErrorType   = DropboxApi::Errors::CreateFileRequestError

    # Create a file request for a given path.
    #
    # @param title [String] The title of the file request. Must not be empty.
    # @param destination [String] The path of the folder in the Dropbox where
    #   uploaded files will be sent. For apps with the app folder permission,
    #   this will be relative to the app folder.
    add_endpoint :create_file_request do |title, destination|
      perform_request({
        title: title,
        destination: destination
      })
    end
  end
end
