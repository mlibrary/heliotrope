# frozen_string_literal: true
module DropboxApi::Endpoints::Sharing
  class ListSharedLinks < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/sharing/list_shared_links'
    ResultType  = DropboxApi::Results::ListSharedLinksResult
    ErrorType   = DropboxApi::Errors::ListSharedLinksError

    include DropboxApi::OptionsValidator

    # List shared links of this user.
    #
    # If no path is given or the path is empty, returns a list of all shared
    # links for the current user.
    #
    # If a non-empty path is given, returns a list of all shared links that
    # allow access to the given path - direct links to the given path and
    # links to parent folders of the given path. Links to parent folders can
    # be suppressed by setting direct_only to true.
    #
    # @option options path [String]
    # @option options cursor [String] The cursor returned by your last call.
    # @option options direct_only [Boolean]
    # @return [ListSharedLinksResult]
    add_endpoint :list_shared_links do |options = {}|
      validate_options([:path, :cursor, :direct_only], options)

      perform_request options
    end
  end
end
