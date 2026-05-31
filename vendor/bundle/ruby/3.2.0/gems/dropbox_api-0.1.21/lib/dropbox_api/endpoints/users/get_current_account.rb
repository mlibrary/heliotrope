# frozen_string_literal: true
module DropboxApi::Endpoints::Users
  class GetCurrentAccount < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/users/get_current_account'
    ResultType  = DropboxApi::Metadata::BasicAccount
    ErrorType   = nil

    # Get information about the current user's account.
    #
    # @return [BasicAccount] Detailed information about the current user's account.
    add_endpoint :get_current_account do
      perform_request nil
    end
  end
end
