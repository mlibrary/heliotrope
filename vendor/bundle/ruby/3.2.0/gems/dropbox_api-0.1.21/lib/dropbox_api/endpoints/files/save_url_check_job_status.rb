# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class SaveUrlCheckJobStatus < DropboxApi::Endpoints::Rpc
    Method      = :post
    Path        = '/2/files/save_url/check_job_status'
    ResultType  = DropboxApi::Results::SaveUrlJobStatus
    ErrorType   = DropboxApi::Errors::PollError

    # Check the status of a `save_url` job.
    #
    # @param job_id [String] Id of the asynchronous job. This is the value of
    #   a response returned from the method that launched the job.
    # @return The current status of the job.
    add_endpoint :save_url_check_job_status do |job_id|
      perform_request({
        async_job_id: job_id
      })
    end
  end
end
