# frozen_string_literal: true

json.extract! component, :id, :handle
json.url component_url(component, format: :json)
