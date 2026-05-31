# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class SaveUrl < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/save_url'
    ResultType  = DropboxApi::Results::SaveUrlResult
    ErrorType   = DropboxApi::Errors::SaveUrlError

    # Save a specified URL into a file in user's Dropbox. If the given path
    # already exists, the file will be renamed to avoid the conflict (e.g.
    # myfile (1).txt).
    #
    # @param path [String] The path in Dropbox where the URL will be saved to.
    # @param url [String] The URL to be saved.
    # @return Either the saved file or a reference to the async job.
    add_endpoint :save_url do |path, url|
      perform_request({
        path: path,
        url: url
      })
    end
  end
end
