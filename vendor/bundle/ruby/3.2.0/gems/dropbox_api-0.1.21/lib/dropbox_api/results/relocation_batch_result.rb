# frozen_string_literal: true
module DropboxApi::Results
  # Result returned by {Client#copy_batch} or {Client#move_batch} that may
  # either launch an asynchronous job or complete synchronously.
  #
  # The value will be either `:in_progress` or a list of job statuses.
  class RelocationBatchResult < DropboxApi::Results::Base
    def self.new(result_data)
      case result_data['.tag']
      when 'in_progress'
        :in_progress
      when 'complete'
        result_data['entries'].map do |entry|
          DropboxApi::Results::RelocationBatchResultEntry.new(entry)
        end
      else
        raise NotImplementedError, "Unknown result type: #{result_data['.tag']}"
      end
    end
  end
end
