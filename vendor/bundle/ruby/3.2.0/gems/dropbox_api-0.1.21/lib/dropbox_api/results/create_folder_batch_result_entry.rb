# frozen_string_literal: true
module DropboxApi::Results
  class CreateFolderBatchResultEntry < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'success'
        DropboxApi::Metadata::Folder.new result_data['metadata']
      when 'failure'
        # At the moment, this is a `CreateFolderEntryError` which is an open
        # union that can only be a `WriteError`. In the future, more errors
        # could be added to the API which means we'd have to implement the
        # actual `CreateFolderEntryError` class.
        DropboxApi::Errors::WriteError
          .build('Folder operation failed', result_data['failure']['path'])
      else
        raise NotImplementedError, "Unknown result type: #{result_data['.tag']}"
      end
    end
  end
end
