# frozen_string_literal: true

json.extract! institution, :id, :identifier, :name, :entity_id
json.url institution_url(institution, format: :json)
