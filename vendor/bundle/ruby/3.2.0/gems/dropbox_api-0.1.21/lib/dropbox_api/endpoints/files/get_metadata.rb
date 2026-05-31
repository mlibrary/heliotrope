# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class GetMetadata < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/get_metadata'
    ResultType  = DropboxApi::Metadata::Resource
    ErrorType   = DropboxApi::Errors::GetMetadataError

    include DropboxApi::OptionsValidator

    # Returns the metadata for a file or folder.
    #
    # Note: Metadata for the root folder is unsupported.
    #
    # If you request the `media_info` attribute, note that it could be set to
    # `:pending` or `nil`.
    #
    # @param path [String] The path of a file or folder on Dropbox.
    # @option options include_media_info [Boolean] If `true`, `media_info`
    #   is set for photo and video. The default for this field is `false`.
    # @option options include_has_explicit_shared_members [Boolean] If `true`,
    #   the results will include a flag for each file indicating whether or
    #   not that file has any explicit members. The default for this field
    #   is `false`.
    # @option options include_deleted [Boolean] If `true`,
    #   {DropboxApi::Metadata::Deleted} will be
    #   returned for deleted file or folder, otherwise
    #   {DropboxApi::Errors::NotFoundError}
    #   will be raised. The default for this field is `false`.
    add_endpoint :get_metadata do |path, options = {}|
      validate_options([
        :include_media_info,
        :include_deleted,
        :include_has_explicit_shared_members
      ], options)

      perform_request(options.merge({
        path: path
      }))
    end
  end
end
