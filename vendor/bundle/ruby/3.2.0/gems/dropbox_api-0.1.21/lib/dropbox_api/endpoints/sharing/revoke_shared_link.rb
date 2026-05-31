# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class RevokeSharedLink < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/revoke_shared_link'
    ResultType  = DropboxApi::Results::VoidResult
    ErrorType   = DropboxApi::Errors::RevokeSharedLinkError

    # Revoke a shared link.
    #
    # Note that even after revoking a shared link to a file, the file may be accessible
    # if there are shared links leading to any of the file parent folders. 
    #
    # A successful response indicates that the shared link was revoked.
    #
    # @param url [String] shared url which needs to be revoked.

    add_endpoint :revoke_shared_link do |url|
      perform_request({
        url: url
      })
    end
  end
end