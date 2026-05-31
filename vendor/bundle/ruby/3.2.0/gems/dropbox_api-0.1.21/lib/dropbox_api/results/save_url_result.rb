# frozen_string_literal: true
module DropboxApi::Results
  class SaveUrlResult < DropboxApi::Results::Base
    # Example with an async job:
    #   {
    #     ".tag": "async_job_id",
    #     "async_job_id": "VofXAX8DO1sAAAAAAAAD_Q"
    #   }
    #
    # I couldn't manage to get anything other than an async job.
    def async_job_id
      @data['async_job_id']
    end
  end
end
