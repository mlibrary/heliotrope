# frozen_string_literal: true
module DropboxApi::Results
  class ShareFolderLaunch
    def self.new(result_data)
      case result_data['.tag']
      when 'complete'
        DropboxApi::Metadata::SharedFolder.new result_data
      when 'async_job_id'
        result_data
      else
        raise ArgumentError, "Unable to infer resource type for `#{tag}`"
      end
    end
  end
end
