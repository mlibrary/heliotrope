# frozen_string_literal: true

json.extract! grouping, :id, :identifier, :created_at, :updated_at
json.url grouping_url(grouping, format: :json)
