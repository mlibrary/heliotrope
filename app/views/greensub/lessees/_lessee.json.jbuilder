# frozen_string_literal: true

json.extract! lessee, :id, :identifier, :created_at, :updated_at
json.url lessee_url(lessee, format: :json)
