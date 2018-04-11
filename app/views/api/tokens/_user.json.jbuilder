# frozen_string_literal: true

json.user do
  json.id user.id
  json.email user.email
  json.url user_url(user.id, format: :json)
end
