# frozen_string_literal: true
module DropboxApi::Results
  class RelocationBatchResultEntry < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'success'
        DropboxApi::Metadata::Resource.new result_data['success']
      when 'failure'
        DropboxApi::Errors::RelocationBatchEntryError
          .build('File or folder operation failed', result_data['failure'])
      else
        raise NotImplementedError, "Unknown result type: #{result_data['.tag']}"
      end
    end
  end
end
