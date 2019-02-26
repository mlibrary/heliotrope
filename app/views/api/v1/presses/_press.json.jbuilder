# frozen_string_literal: true

json.extract! press, :id, :subdomain, :name
json.url press_url(press, format: :json)
