# frozen_string_literal: true
module DropboxApi::Metadata
  # An action will be one of the following:
  #
  # - `:leave_a_copy`: Allow the member to keep a copy of the folder when
  #   removing.
  # - `:make_editor`: Make the member an editor of the folder.
  # - `:make_owner`: Make the member an owner of the folder.
  # - `:make_viewer`: Make the member a viewer of the folder.
  # - `:make_viewer_no_comment`: Make the member a viewer of the folder without
  #   commenting permissions.
  # - `:remove`: Remove the member from the folder.
  #
  # Example of a serialized {MemberAction} object:
  #
  # ```json
  # {
  #   ".tag": "leave_a_copy"
  # }
  # ```
  class MemberAction < DropboxApi::Metadata::Tag
    VALID_MEMBER_ACTIONS = [
      :leave_a_copy,
      :make_editor,
      :make_owner,
      :make_viewer,
      :make_viewer_no_comment,
      :remove
    ]

    def self.valid_values
      VALID_MEMBER_ACTIONS
    end
  end
end
