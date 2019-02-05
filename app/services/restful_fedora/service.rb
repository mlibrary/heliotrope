# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'json'

module RestfulFedora
  class Service
    def contains
      response = connection.get do |request|
        request.url RestfulFedora.base_path
        request.options[:timeout] = 3600 # 1 hour
        request.options[:open_timeout] = 4800 # 1.5 hours
      end
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
          conn.adapter Faraday.default_adapter
        end
      end
  end
end
