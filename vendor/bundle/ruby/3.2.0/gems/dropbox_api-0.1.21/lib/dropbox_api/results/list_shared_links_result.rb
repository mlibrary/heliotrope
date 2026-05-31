# frozen_string_literal: true
module DropboxApi::Results
  class ListSharedLinksResult < DropboxApi::Results::Base
    #  Shared links applicable to the path argument.
    def links
      @entries ||= @data['links'].map do |entry|
        DropboxApi::Metadata::SharedLinkMetadata.new entry
      end
    end

    # Pass the cursor into `list_folder_continue` to see what's changed in the
    # folder since your previous query.
    def cursor
      @data['cursor']
    end

    # If true, then there are more entries available. Pass the cursor to
    # `list_folder_continue` to retrieve the rest.
    def has_more?
      @data['has_more'].to_s == 'true'
    end
  end
end
