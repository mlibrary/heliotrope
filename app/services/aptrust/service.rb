# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'json'

module Aptrust
  class Service
    def ingest_status(identifier) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      response = connection.get("items?object_identifier=#{identifier}&item_action=Ingest")

      return 'http_error' unless response.success?

      results = response.body['results']

      return 'not_found' if results.empty?

      item = results.first

      return 'failed' if /failed/i.match?(item['status']) || /cancelled/i.match?(item['status'])

      return 'success' if /cleanup/i.match?(item['stage']) && /success/i.match?(item['status'])

      'processing'
    rescue StandardError => e
      Rails.logger.error "Aptrust::Service.ingest_status(#{identifier}) #{e}"
      'standard_error'
    end

    def initialize(options = {})
      @base = options[:base]
      @base ||= begin
        filename = Rails.root.join('config', 'aptrust.yml')
        @yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
        @yaml ||= {}
        @yaml['AptrustApiUrl']
      end
    end

    private

      def connection
        @connection ||= Faraday.new(@base) do |conn|
          conn.headers = {
            accept: "application/json",
            content_type: "application/json",
            "X-Pharos-API-User" => @yaml['AptrustApiUser'],
            "X-Pharos-API-Key" => @yaml['AptrustApiKey']
          }
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.options[:open_timeout] = 60 # seconds, 1 minute, opening a connection
          conn.options[:timeout] = 60 # seconds, 1 minute, waiting for response
          conn.adapter Faraday.default_adapter
        end
      end
  end
end
