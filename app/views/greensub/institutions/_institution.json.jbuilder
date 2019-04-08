# frozen_string_literal: true

json.extract! institution, :id, :identifier, :name, :site, :login, :created_at, :updated_at
json.url institution_url(institution, format: :json)
