# frozen_string_literal: true
module DropboxApi::Errors
  class CreateSharedLinkWithSettingsError < BasicError
    ErrorSubtypes = {
      path: LookupError,
      email_not_verified: EmailUnverifiedError,
      shared_link_already_exists: SharedLinkAlreadyExistsError,
      settings_error: SettingsError,
      access_denied: NoPermissionError
    }.freeze
  end
end
