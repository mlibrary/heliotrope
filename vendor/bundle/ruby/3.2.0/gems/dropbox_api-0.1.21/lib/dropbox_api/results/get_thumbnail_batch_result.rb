# frozen_string_literal: true
module DropboxApi::Results
  class GetThumbnailBatchResult < DropboxApi::Results::Base
    def entries
      @entries ||= @data['entries'].map do |entry|
        DropboxApi::Metadata::ThumbnailBatchResultEntry.new entry
      end
    end
  end
end
