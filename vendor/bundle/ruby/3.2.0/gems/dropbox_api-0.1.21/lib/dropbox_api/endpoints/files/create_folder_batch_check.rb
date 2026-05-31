# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class CreateFolderBatchCheck < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/create_folder_batch/check'
    ResultType  = DropboxApi::Results::CreateFolderBatchResult
    ErrorType   = DropboxApi::Errors::PollError

    # Returns the status of an asynchronous job for create_folder_batch.
    # If success, it returns list of result for each entry.
    #
    # @param async_job_id [String] Id of the asynchronous job.
    #   This is the value of a response returned from the method that launched
    #   the job.
    # @return [Array] A list of one result for each entry.
    add_endpoint :create_folder_batch_check do |async_job_id|
      perform_request({
        async_job_id: async_job_id
      })
    end
  end
end
