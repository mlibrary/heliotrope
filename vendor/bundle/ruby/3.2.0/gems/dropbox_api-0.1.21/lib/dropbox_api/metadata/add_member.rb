# frozen_string_literal: true
module DropboxApi::Metadata
  # Examples of serialized {AddMember} objects:
  #
  # ```json
  # {
  #   "member": {
  #     ".tag": "email",
  #     "email": "justin@example.com"
  #   },
  #   "access_level": {
  #     ".tag": "editor"
  #   }
  # },
  # {
  #   "member": {
  #     ".tag": "dropbox_id",
  #     "dropbox_id": "dbid:AAEufNrMPSPe0dMQijRP0N_aZtBJRm26W4Q"
  #   },
  #   "access_level": {
  #     ".tag": "viewer"
  #   }
  # }
  # ```
  class AddMember < Base
    class << self
      def build_from_string(member, access_level = :editor)
        new({
          'member' => Member.new(member),
          'access_level' => access_level
        })
      end
    end

    field :member, DropboxApi::Metadata::Member
    field :access_level, DropboxApi::Metadata::AccessLevel
  end
end
