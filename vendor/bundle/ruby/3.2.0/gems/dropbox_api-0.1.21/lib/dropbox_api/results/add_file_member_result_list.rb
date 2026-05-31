# frozen_string_literal: true
module DropboxApi::Results
  # Example of a result of the `add_file_member` endpoint:
  #   [{
  #     "member":{
  #       ".tag": "email",
  #       "email": "somebody@test.com"
  #     },
  #     "result": {
  #       ".tag": "success",
  #       "success": {
  #         ".tag": "viewer"
  #       }
  #     }
  #   }]
  class AddFileMemberResultList < Array
    def initialize(members)
      super(members.map { |m| DropboxApi::Metadata::AddFileMemberResult.new m })
    end
  end
end
