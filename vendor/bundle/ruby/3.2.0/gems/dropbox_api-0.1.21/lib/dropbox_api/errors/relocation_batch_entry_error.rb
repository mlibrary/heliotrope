# frozen_string_literal: true
module DropboxApi::Errors
  class RelocationBatchEntryError < BasicError
    ErrorSubtypes = {
      relocation_error: RelocationError,
      internal_error: InternalError,
      too_many_write_operations: TooManyWriteOperationsError
    }.freeze
  end
end