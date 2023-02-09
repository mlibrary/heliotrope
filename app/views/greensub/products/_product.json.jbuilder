# frozen_string_literal: true

json.extract! product, :id, :identifier, :name, :needs_kbart, :group_key, :created_at, :updated_at
json.url greensub_product_url(product, format: :json)
