# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class Delete < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/delete'
    ResultType  = DropboxApi::Metadata::Resource
    ErrorType   = DropboxApi::Errors::DeleteError

    include DropboxApi::OptionsValidator

    # Delete the file or folder at a given path.
    #
    # If the path is a folder, all its contents will be deleted too.
    #
    # A successful response indicates that the file or folder was deleted.
    # The returned metadata will be the corresponding
    # {DropboxApi::Metadata::File} or {DropboxApi::Metadata::Folder} for the
    # item at time of deletion, and not a {DropboxApi::Metadata::Deleted} object.
    #
    # @param path [String] Path in the user's Dropbox to delete.
    # @option options parent_rev [String] Perform delete if given "rev"
    #   matches the existing file's latest "rev". This field does not support
    #   deleting a folder. If the given "rev" doesn't match, a
    #   {DropboxApi::Errors::FileConflictError} will be raised.
    add_endpoint :delete do |path, options = {}|
      validate_options([:parent_rev], options)

      perform_request options.merge({
        path: path
      })
    end
  end
end
