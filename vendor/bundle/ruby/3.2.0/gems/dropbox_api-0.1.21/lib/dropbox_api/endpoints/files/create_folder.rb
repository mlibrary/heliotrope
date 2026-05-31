# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class CreateFolder < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/create_folder'
    ResultType  = DropboxApi::Metadata::Folder
    ErrorType   = DropboxApi::Errors::CreateFolderError

    # Create a folder at a given path.
    #
    # @param path [String] Path in the user's Dropbox to create.
    # @return [DropboxApi::Metadata::Folder] The new folder.
    add_endpoint :create_folder do |path|
      perform_request({
        path: path
      })
    end
  end
end
