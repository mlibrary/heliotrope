# frozen_string_literal: true
module DropboxApi::Results
  class UploadSessionStart < DropboxApi::Results::Base
    def session_id
      @data['session_id']
    end
  end
end
