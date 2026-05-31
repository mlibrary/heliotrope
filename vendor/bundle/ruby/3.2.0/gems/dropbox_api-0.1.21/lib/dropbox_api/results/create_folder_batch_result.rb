# frozen_string_literal: true
module DropboxApi::Results
  # Result returned by {Client#create_folder_batch} that may either launch an
  # asynchronous job or complete synchronously.
  #
  # The value will be either a job id or a list of job statuses.
  class CreateFolderBatchResult < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'async_job_id'
        result_data
      when 'complete'
        result_data['entries'].map do |entry|
          DropboxApi::Results::CreateFolderBatchResultEntry.new(entry)
        end
      else
        raise NotImplementedError, "Unknown result type: #{result_data['.tag']}"
      end
    end
  end
end
