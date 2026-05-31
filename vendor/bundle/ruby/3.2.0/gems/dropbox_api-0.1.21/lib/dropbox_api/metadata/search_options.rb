# frozen_string_literal: true

module DropboxApi::Metadata
  class SearchOptions < Base
    # Scopes the search to a path in the user's Dropbox. Searches the entire
    # Dropbox if not specified. This field is optional.
    field :path, String, :optional

    # The maximum number of search results to return. The default for this
    # field is 100.
    field :max_results, Integer, :optional

    # Specified property of the order of search results. By default, results
    # are sorted by relevance. This field is optional.
    field :order_by, DropboxApi::Metadata::SearchOrderBy, :optional

    # Restricts search to the given file status. The default for this union
    # is active.
    field :file_status, DropboxApi::Metadata::FileStatus, :optional

    # Restricts search to only match on filenames. The default for this field
    # is false.
    field :filename_only, :boolean, :optional

    # Restricts search to only the extensions specified. Only supported for
    # active file search. This field is optional.
    field :file_extensions, DropboxApi::Metadata::FileExtensionsList, :optional

    # Restricts search to only the file categories specified. Only supported
    # for active file search. This field is optional.
    field :file_categories, DropboxApi::Metadata::FileCategoriesList, :optional
  end
end
