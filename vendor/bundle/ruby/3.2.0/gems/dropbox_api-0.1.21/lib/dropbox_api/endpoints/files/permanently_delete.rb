# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class PermanentlyDelete < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/permanently_delete'
    ResultType  = DropboxApi::Results::VoidResult
    ErrorType   = DropboxApi::Errors::DeleteError

    include DropboxApi::OptionsValidator

    # Permanently delete the file or folder at a given path.
    #
    # See https://www.dropbox.com/en/help/40
    #
    # Note: This endpoint is only available for Dropbox Business apps.
    #
    # @param path [String] Path in the user's Dropbox to delete.
    # @option options parent_rev [String] Perform delete if given "rev"
    #   matches the existing file's latest "rev". This field does not support
    #   deleting a folder.
    add_endpoint :permanently_delete do |path, options = {}|
      validate_options([:parent_rev], options)

      perform_request options.merge({
        path: path
      })
    end
  end
end
