# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class Search < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/search_v2'
    ResultType  = DropboxApi::Results::SearchV2Result
    ErrorType   = DropboxApi::Errors::SearchError

    include DropboxApi::OptionsValidator

    # Searches for files and folders.
    #
    # Note: Recent changes may not immediately be reflected in search results
    # due to a short delay in indexing.
    #
    # @param query [String] The string to search for. May match across
    #   multiple fields based on the request arguments.
    # @param options [DropboxApi::Metadata::SearchOptions] Options for more
    #   targeted search results. This field is optional.
    # @param match_field_options [DropboxApi::Metadata::SearchMatchFieldOptions]
    #   Options for search results match fields. This field is optional.
    add_endpoint :search do |query, options = nil, match_field_options = nil|
      params = { query: query }

      params[:options] = options.to_hash unless options.nil?

      params[:match_field_options] = match_field_options.to_hash unless match_field_options.nil?

      perform_request(params)
    end
  end
end
