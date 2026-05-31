# frozen_string_literal: true
module DropboxApi::Endpoints::Auth
  class TokenRevoke < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/auth/token/revoke'
    ResultType  = DropboxApi::Results::VoidResult
    ErrorType   = nil

    # Revoke the access token for the current account
    #
    add_endpoint :token_revoke do
      perform_request(nil)
    end
  end
end
