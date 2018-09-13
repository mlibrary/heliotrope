# frozen_string_literal: true

module HeliotropeHyraxUserBehavior
  # https://tools.lib.umich.edu/jira/browse/HELIO-2065
  # need an overwrite of this as we don't store passwords now, with Shibboleth
  def find_or_create_system_user(user_key)
    User.find_by(email: user_key) || User.create!(email: user_key)
  end
end
