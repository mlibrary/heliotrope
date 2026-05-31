# frozen_string_literal: true
module DropboxApi::Results
  class DeleteBatchResultEntry < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'success'
        DropboxApi::Metadata::Resource.new result_data['metadata']
      when 'failure'
        DropboxApi::Errors::DeleteError
          .build('Delete operation failed', result_data['failure'])
      else
        raise NotImplementedError, "Unknown result type: #{result_data['.tag']}"
      end
    end
  end
end
