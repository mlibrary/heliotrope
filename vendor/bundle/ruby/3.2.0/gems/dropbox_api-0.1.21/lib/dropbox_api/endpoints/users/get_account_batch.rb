# frozen_string_literal: true
module DropboxApi::Endpoints::Users
  class GetAccountBatch < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/users/get_account_batch'
    ResultType  = DropboxApi::Results::BasicAccountBatch
    ErrorType   = DropboxApi::Errors::GetAccountError

    # Get information about multiple user accounts. At most 300 accounts may
    # be queried per request.
    #
    # @param account_ids [Array<String>] List of user account identifiers. Should not
    #   contain any duplicate account IDs.
    # @return [Array<BasicAccount>] Basic information about any account.
    add_endpoint :get_account_batch do |account_ids|
      perform_request account_ids: account_ids
    end
  end
end
