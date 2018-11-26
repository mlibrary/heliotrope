# frozen_string_literal: true

json.extract! product, :id, :identifier, :name, :purchase
json.url product_url(product, format: :json)
