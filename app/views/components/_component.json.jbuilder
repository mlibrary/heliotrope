# frozen_string_literal: true

json.extract! component, :id, :identifier, :name, :noid, :handle
json.url component_url(component, format: :json)
