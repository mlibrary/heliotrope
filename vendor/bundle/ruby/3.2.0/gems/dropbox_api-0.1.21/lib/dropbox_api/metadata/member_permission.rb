# frozen_string_literal: true
module DropboxApi::Metadata
  # This is an example of a serialized {MemberPermission}:
  # 
  # ```json
  # {
  #   "action": {
  #     ".tag": "remove"
  #   },
  #   "allow": false,
  #   "reason": {
  #     ".tag": "target_is_self"
  #   }
  # }
  # ```
  #
  # This is normally contained in a {MemberPermissionList} object.
  class MemberPermission < Base
    field :action, DropboxApi::Metadata::MemberAction
    field :allow, :boolean
    field :reason, String # This is actually a PermissionDeniedReason object
  end
end
