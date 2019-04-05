# frozen_string_literal: true

json.extract! product, :id, :identifier, :name, :purchase
json.url greensub_product_url(product, format: :json)
