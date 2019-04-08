# frozen_string_literal: true

json.extract! individual, :id, :identifier, :name, :email
json.url greensub_individual_url(individual, format: :json)
