# frozen_string_literal: true

json.extract! component, :id, :handle, :created_at, :updated_at
json.url component_url(component, format: :json)
