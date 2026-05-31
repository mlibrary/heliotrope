# frozen_string_literal: true
module DropboxApi::Errors
  class SearchError < BasicError
    ErrorSubtypes = {
      path: LookupError
    }.freeze
  end
end
