# frozen_string_literal: true
module DropboxApi::Results
  class CopyBatchResult < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'async_job_id'
        result_data['async_job_id']
      when 'complete'
        RelocationBatchResult.new(result_data)
      else
        raise NotImplementedError, "Unknown result type: #{result_data['.tag']}"
      end
    end
  end
end
