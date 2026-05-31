# frozen_string_literal: true
module DropboxApi::Results
  class SaveUrlJobStatus < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'in_progress'
        :in_progress
      when 'complete'
        DropboxApi::Metadata::File.new result_data
      when 'failed'
        DropboxApi::Errors::SaveUrlError.build('Async job failed',
                                               result_data['failed'])
      else
        raise NotImplementedError, "Unknown result type: #{result_data[".tag"]}"
      end
    end
  end
end
