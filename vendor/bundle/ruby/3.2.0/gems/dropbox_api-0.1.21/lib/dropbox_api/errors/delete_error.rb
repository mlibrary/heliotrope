# frozen_string_literal: true
module DropboxApi::Errors
  class DeleteError < BasicError
    ErrorSubtypes = {
      path_lookup: LookupError,
      path_write: WriteError,
      too_many_write_operations: TooManyWriteOperationsError
    }.freeze
  end
end