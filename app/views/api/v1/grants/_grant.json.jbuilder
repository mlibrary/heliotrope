# frozen_string_literal: true

json.extract! grant, :id
json.url grant_url(grant, format: :json)
