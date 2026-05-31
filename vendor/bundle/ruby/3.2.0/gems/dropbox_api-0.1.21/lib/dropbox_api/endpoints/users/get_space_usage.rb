# frozen_string_literal: true
module DropboxApi::Endpoints::Users
  class GetSpaceUsage < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/users/get_space_usage'
    ResultType  = DropboxApi::Metadata::SpaceUsage
    ErrorType   = nil

    # Get the space usage information for the current user's account.
    #
    # @return [SpaceUsage] Information about a user's space usage and quota.
    add_endpoint :get_space_usage do
      perform_request nil
    end
  end
end
