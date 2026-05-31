# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class Move < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/move'
    ResultType  = DropboxApi::Metadata::Resource
    ErrorType   = DropboxApi::Errors::RelocationError

    include DropboxApi::OptionsValidator

    # Move a file or folder to a different location in the user's Dropbox.
    #
    # If the source path is a folder all its contents will be moved.
    #
    # @param from [String] Path in the user's Dropbox to be copied or moved.
    # @param to [String] Path in the user's Dropbox that is the destination.
    # @option options autorename [Boolean] If there's a conflict, have the
    #   Dropbox server try to autorename the file to avoid the conflict. The
    #   default for this field is `false`.
    add_endpoint :move do |from, to, options = {}|
      # We're not implementing support for the `allow_shared_folder` option
      # because according to Dropbox's documentation: "This field is always
      # true for move".
      validate_options([
        :autorename
      ], options)

      perform_request options.merge({
        from_path: from,
        to_path: to
      })
    end
  end
end
