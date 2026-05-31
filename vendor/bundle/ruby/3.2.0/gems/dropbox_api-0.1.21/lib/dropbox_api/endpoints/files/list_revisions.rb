# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class ListRevisions < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/list_revisions'
    ResultType  = DropboxApi::Results::ListRevisionsResult
    ErrorType   = DropboxApi::Errors::ListRevisionsError

    include DropboxApi::OptionsValidator

    # Return revisions of a file
    #
    # @param path [String] The path to file you want to see the revisions of.
    # @option options limit [Numeric] The maximum number of revision entries
    #   returned. The default for this field is 10.
    add_endpoint :list_revisions do |path, options = {}|
      validate_options([
        :limit
      ], options)
      options[:limit] ||= 10

      perform_request options.merge({
        path: path
      })
    end
  end
end
