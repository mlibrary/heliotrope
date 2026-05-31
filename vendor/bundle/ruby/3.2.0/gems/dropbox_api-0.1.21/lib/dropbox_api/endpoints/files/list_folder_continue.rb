# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class ListFolderContinue < DropboxApi::Endpoints::Rpc
    # NOTE: This hasn't been tested with real data, I couldn't make a query
    #       long enough to enable the `has_more` attribute in the
    #       `ListFolderResult`.
    Method      = :post
    Path        = '/2/files/list_folder/continue'
    ResultType  = DropboxApi::Results::ListFolderResult
    ErrorType   = DropboxApi::Errors::ListFolderContinueError

    # Once a cursor has been retrieved from `list_folder`, use this to paginate
    # through all files and retrieve updates to the folder.
    #
    # @param cursor [String] The cursor returned by your last call to
    #   list_folder or list_folder_continue.
    add_endpoint :list_folder_continue do |cursor|
      perform_request cursor: cursor
    end
  end
end
