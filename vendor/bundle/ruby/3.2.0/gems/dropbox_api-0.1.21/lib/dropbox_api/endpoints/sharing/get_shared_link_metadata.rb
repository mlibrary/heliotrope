# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class GetSharedLinkMetadata < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/get_shared_link_metadata'
    ResultType  = DropboxApi::Metadata::SharedLinkMetadata
    ErrorType   = DropboxApi::Errors::SharedLinkError

    include DropboxApi::OptionsValidator

    # Get the Metadata for a shared link
    #
    # If a preview url is given, returns the shared file or folder
    # that is represent by that link.
    #
    # @option options path [String] If the shared link is to a folder,
    #  this parameter can be used to retrieve the metadata for a
    #  specific file or sub-folder in this folder. A relative path
    #  should be used.
    # @option options link_password [String] If the shared link has
    #   a password, this parameter can be used.
    # @return [SharedFileMembers]
    add_endpoint :get_shared_link_metadata do |preview_link, options = {}|
      validate_options([:path, :link_password], options)

      perform_request options.merge(
        url: preview_link
      )
    end
  end
end
