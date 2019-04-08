# frozen_string_literal: true

json.extract! component, :id, :identifier, :name, :noid
json.url greensub_component_url(component, format: :json)
