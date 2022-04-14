# frozen_string_literal: true

module RestfulSolr
  class Service
    def contains
      response = connection.get('select?q=&fl=id&wt=json')
      return [] unless response.success? && response.body.present? && response.body.is_a?(Hash)
      docs = response.body['response']['docs'] || []
      docs.map { |h| h['id'] }
    end

    def initialize(options = {})
      @base = options[:base] || RestfulSolr.url
    end

    private

      def connection
        @connection ||= Faraday.new(@base) do |conn|
          conn.headers = {
            accept: "application/json",
            content_type: "application/json"
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
