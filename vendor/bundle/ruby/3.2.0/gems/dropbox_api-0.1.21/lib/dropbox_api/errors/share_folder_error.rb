# frozen_string_literal: true
module DropboxApi::Errors
  class ShareFolderError < BasicError
    ErrorSubtypes = {
      email_unverified: EmailUnverifiedError,
      bad_path: SharePathError,
      team_policy_disallows_member_policy: TeamPolicyDisallowsMemberPolicyError,
      disallowed_shared_link_policy: DisallowedSharedLinkPolicyError,
      no_permission: NoPermissionError
    }.freeze
  end
end
