# frozen_string_literal: true
module DropboxApi::Results
  class ListRevisionsResult < DropboxApi::Results::Base
    # A collection of files and directories.
    def entries
      @entries ||= @data['entries'].map do |entry|
        DropboxApi::Metadata::File.new entry
      end
    end

    def is_deleted?
      @data['is_deleted'] == true
    end
  end
end
