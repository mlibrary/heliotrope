# frozen_string_literal: true

json.extract! product, :id, :identifier, :name
json.url product_url(product, format: :json)
