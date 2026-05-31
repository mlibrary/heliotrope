# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class DeleteBatchCheck < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/delete_batch/check'
    ResultType  = DropboxApi::Results::DeleteBatchResult
    ErrorType   = DropboxApi::Errors::PollError

    # Returns the status of an asynchronous job for delete_batch. If success,
    # it returns list of result for each entry.
    #
    # @param async_job_id [String] Id of the asynchronous job.
    # @return [:in_progress, Array] This could be either the `:in_progress`
    #   flag or a list of job statuses.
    add_endpoint :delete_batch_check do |async_job_id|
      perform_request({
        async_job_id: async_job_id
      })
    end
  end
end
