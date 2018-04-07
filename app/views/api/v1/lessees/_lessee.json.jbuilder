# frozen_string_literal: true

json.extract! lessee, :id, :identifier
json.url lessee_url(lessee, format: :json)
