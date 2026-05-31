# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class Copy < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/copy'
    ResultType  = DropboxApi::Metadata::Resource
    ErrorType   = DropboxApi::Errors::RelocationError

    # Copy a file or folder to a different location in the user's Dropbox.
    # If the source path is a folder all its contents will be copied.
    #
    # @param from [String] Path in the user's Dropbox to be copied or moved.
    # @param to [String] Path in the user's Dropbox that is the destination.
    # @return The moved file.
    add_endpoint :copy do |from, to|
      perform_request({
        from_path: from,
        to_path: to
      })
    end
  end
end
