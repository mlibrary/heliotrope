# frozen_string_literal: true

json.extract! component, :id, :identifier, :name, :noid, :handle
json.url greensub_component_url(component, format: :json)
