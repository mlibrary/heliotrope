# frozen_string_literal: true
module DropboxApi::Errors
  class AddFolderMemberError < BasicError
    ErrorSubtypes = {
      access_error: SharedFolderAccessError,
      email_unverified: EmailUnverifiedError,
      bad_member: AddMemberSelectorError,
      cant_share_outside_team: CantShareOutsideTeamError,
      too_many_members: TooManyMembersError,
      too_many_pending_invites: TooManyPendingInvitesError,
      rate_limit: RateLimitError,
      insufficient_plan: InsufficientPlanError,
      team_folder: TeamFolderError,
      no_permission: NoPermissionError
    }.freeze
  end
end
