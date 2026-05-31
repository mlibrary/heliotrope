# frozen_string_literal: true
module DropboxApi::Errors
  class SettingsError < BasicError
    ErrorSubtypes = {
      invalid_settings: InvalidSettingsError,
      not_authorized: NoPermissionError
    }.freeze
  end
end
