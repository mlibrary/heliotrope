# frozen_string_literal: true
module DropboxApi::Results
  class ListFolderGetLatestCursorResult < DropboxApi::Results::Base
    def cursor
      @data['cursor']
    end
  end
end
