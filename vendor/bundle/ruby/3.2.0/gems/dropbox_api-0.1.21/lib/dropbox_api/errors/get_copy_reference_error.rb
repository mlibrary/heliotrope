# frozen_string_literal: true
module DropboxApi::Errors
  class GetCopyReferenceError < BasicError
    ErrorSubtypes = {
      path: LookupError
    }.freeze
  end
end
