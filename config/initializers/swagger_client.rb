# frozen_string_literal: true

require 'swagger_client'

# Use this setup block to configure all options available in SwaggerClient.
SwaggerClient.configure do |config|
  config.scheme = 'http' unless Rails.env.production?
  config.host = Settings.host
  config.base_path = '/api/sushi'
  # config.api_key['apikey'] = ENV['HELIOTROPE_TOKEN']
  # config.api_key_prefix['apikey'] = 'Bearer'
  # config.api_key['requestor_id'] = ENV['HELIOTROPE_TOKEN']
  # config.api_key_prefix['requestor_id'] = 'Bearer'
end
