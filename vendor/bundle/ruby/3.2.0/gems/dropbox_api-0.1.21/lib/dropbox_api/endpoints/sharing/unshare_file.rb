# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class UnshareFile < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/unshare_file'
    ResultType  = DropboxApi::Results::VoidResult
    ErrorType   = DropboxApi::Errors::UnshareFileError

    # Remove all members from this file. Does not remove inherited members.
    #
    # A successful response indicates that the file was unshared.
    #
    # @param file [String] Path or ID of the file in the user's Dropbox to unshare.
    add_endpoint :unshare_file do |file|
      perform_request({
        file: file
      })
    end
  end
end
