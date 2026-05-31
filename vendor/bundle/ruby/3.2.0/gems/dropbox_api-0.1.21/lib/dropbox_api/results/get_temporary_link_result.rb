# frozen_string_literal: true
module DropboxApi::Results
  class GetTemporaryLinkResult < DropboxApi::Results::Base
    def file
      @file ||= DropboxApi::Metadata::File.new(@data['metadata'])
    end

    def link
      @data['link']
    end
  end
end
