# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'json'

module RestfulFedora
  class Service
    def contains
      response = connection.get(RestfulFedora.base_path)
      return [] unless response.success? && response.body.present? && response.body.first.present? && response.body.first.is_a?(Hash)
      ldp_contains = response.body.first["http://www.w3.org/ns/ldp#contains"] || []
      ldp_contains.map { |h| h["@id"] }
    end

    def initialize(options = {})
      @base = options[:base] || RestfulFedora.url
    end

    private
      def connection
        @connection ||= Faraday.new(@base) do |conn|
          conn.headers = {
            accept: "application/ld+json",
            content_type: "application/ld+json"
          }
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.options[:open_timeout] = 60 # seconds, 1 minute, opening a connection
          conn.options[:timeout] = 600 # seconds, 10 minutes, waiting for response
          conn.adapter Faraday.default_adapter
        end
      end
  end
end
