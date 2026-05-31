# frozen_string_literal: true
module DropboxApi::Errors
  class RestoreError < BasicError
    ErrorSubtypes = {
      path_lookup: LookupError,
      path_write: WriteError,
      invalid_revision: InvalidRevisionError
    }.freeze
  end
end
