# frozen_string_literal: true

module Aptrust
  class Service
    def ingest_status(identifier) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # For API V3 we need identifiers that look like fulcrum.org/fulcrum.org.michelt-zc77ss45g
      # and not just fulcrum.org.michelt-zc77ss45g
      # This "Work Items" endpoint always returns multiple, paginated results. Hence `results.first` below.
      # See https://aptrust.github.io/registry/#/Work%20Items
      # We'll request one result per page, and use a "date desc" sort to get the most recently-processed ingest for this identifier.
      response = connection.get("items?object_identifier=fulcrum.org\/#{identifier}&action=Ingest&per_page=1&sort=date_processed__desc")

      return 'http_error' unless response.success?

      results = response.body['results']

      return 'not_found' if results.blank?

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
