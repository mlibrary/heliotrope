# frozen_string_literal: true

json.extract! monograph, :id, :title
json.url monograph_catalog_url(monograph, format: :json)
