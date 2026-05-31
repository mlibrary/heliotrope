# frozen_string_literal: true
module DropboxApi::Endpoints::Users
  class GetAccount < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/users/get_account'
    ResultType  = DropboxApi::Metadata::BasicAccount
    ErrorType   = DropboxApi::Errors::GetAccountError

    # Get information about a user's account.
    #
    # @param account_id [String] A user's account identifier.
    # @return [BasicAccount] Basic information about any account.
    add_endpoint :get_account do |account_id|
      perform_request account_id: account_id
    end
  end
end
