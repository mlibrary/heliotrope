# frozen_string_literal: true
module DropboxApi::Errors
  class PollError < BasicError
    ErrorSubtypes = {
      invalid_async_job_id: InvalidIdError,
      internal_error: InternalError
    }.freeze
  end
end
