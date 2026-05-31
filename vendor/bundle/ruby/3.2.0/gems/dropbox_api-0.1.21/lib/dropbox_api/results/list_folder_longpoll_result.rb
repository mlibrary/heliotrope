# frozen_string_literal: true
module DropboxApi::Results
  class ListFolderLongpollResult < DropboxApi::Results::Base
    # Indicates whether new changes are available. If true, call
    # `list_folder_continue` to retrieve the changes.
    def changes
      @data['changes'].to_s == 'true'
    end

    # If present, backoff for at least this many seconds before calling
    # `list_folder_longpoll` again. This field is optional.
    def backoff
      @data['backoff']
    end
  end
end
