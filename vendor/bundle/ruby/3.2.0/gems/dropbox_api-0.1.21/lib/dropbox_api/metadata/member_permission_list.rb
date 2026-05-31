# frozen_string_literal: true
module DropboxApi::Metadata
  # This represents a collection of permissions on allowed on a
  # shared file or folder.
  #
  # This is an example of a serialized {MemberActionList}:
  # ```json
  # [{
  #   "action": {
  #     ".tag": "remove"
  #   },
  #   "allow": false,
  #   "reason": {
  #     ".tag": "target_is_self"
  #   }
  # }, {
  #   "action": {
  #     ".tag": "make_owner"
  #   },
  #   "allow": false,
  #   "reason": {
  #     ".tag": "target_is_self"
  #   }
  # }]
  # ```
  class MemberPermissionList < Array
    def initialize(list)
      super(list.map { |i| DropboxApi::Metadata::MemberPermission.new i })
    end
  end
end
