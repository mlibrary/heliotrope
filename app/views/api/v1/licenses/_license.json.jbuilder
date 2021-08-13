# frozen_string_literal: true

json.extract! license, :id, :type, :licensee_type, :licensee_id, :product_id
json.url greensub_license_url(license, format: :json)
