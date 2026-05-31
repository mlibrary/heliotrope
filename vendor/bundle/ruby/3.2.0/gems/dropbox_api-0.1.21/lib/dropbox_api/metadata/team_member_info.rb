# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {TeamMemberInfo} object:
  #
  # ```json
  # {
  #   "team_info": {
  #     "id": "dbtid:AAFdgehTzw7WlXhZJsbGCLePe8RvQGYDr-I",
  #     "name": "Acme, Inc."
  #   },
  #   "display_name": "Roger Rabbit",
  #   "member_id": "dbmid:abcd1234"
  # }
  # ```
  class TeamMemberInfo < Base
    field :team_info, DropboxApi::Metadata::Team
    field :display_name, String
    field :member_id, String, :optional
  end
end
