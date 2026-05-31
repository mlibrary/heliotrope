# frozen_string_literal: true
module DropboxApi::Errors
  class AddMemberSelectorError < BasicError
    ErrorSubtypes = {
      invalid_dropbox_id: InvalidDropboxIdError,
      invalid_email: InvalidEmailError,
      unverified_dropbox_id: UnverifiedDropboxId,
      group_deleted: GroupDeletedError,
      group_not_on_team: GroupNotOnTeamError
    }.freeze
  end
end
