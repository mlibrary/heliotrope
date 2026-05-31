# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class Restore < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/restore'
    ResultType  = DropboxApi::Metadata::File
    ErrorType   = DropboxApi::Errors::RestoreError

    # Restore a file to a specific revision
    #
    # @param path [String] The path to the file you want to restore.
    # @param rev [String] The revision to restore for the file.
    add_endpoint :restore do |path, rev|
      perform_request({
        path: path,
        rev: rev
      })
    end
  end
end
