# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'json'

module Turnsole
  class Service
    #
    # Presses
    #
    def find_press(subdomain)
      response = connection.get("press", subdomain: subdomain)
      return response.body["id"] if response.success?
      nil
    rescue StandardError => e
      Rails.logger.error e.message
      nil
    end

    def presses
      response = connection.get('presses')
      return response.body if response.success?
      []
    rescue StandardError => e
      Rails.logger.error e.message
      []
    end

    def press(id)
      response = connection.get("presses/#{id}")
      return response.body['id'] if response.success?
      nil
    rescue StandardError => e
      Rails.logger.error e.message
      nil
    end

    def press_monographs(id)
      response = connection.get("presses/#{id}/monographs")
      return response.body if response.success?
      []
    rescue StandardError => e
      Rails.logger.error e.message
      []
    end

    #
    # Monographs
    #
    def monographs
      response = connection.get('monographs')
      return response.body if response.success?
      []
    rescue StandardError => e
      Rails.logger.error e.message
      []
    end

    def monograph(id)
      response = connection.get("monographs/#{id}")
      return response.body['id'] if response.success?
      nil
    rescue StandardError => e
      Rails.logger.error e.message
      nil
    end

    def monograph_extract(id)
      response = connection.get("monographs/#{id}/extract")
      response.body
    rescue StandardError => e
      Rails.logger.error e.message
      e.message
    end

    def monograph_manifest(id)
      response = connection.get("monographs/#{id}/manifest")
      response.body
    rescue StandardError => e
      Rails.logger.error e.message
      e.message
    end

    #
    # Configuration
    #
    def initialize(token, base)
      @token = token
      @base = base
    end

    private

      #
      # Connection
      #
      def connection
        @connection ||= Faraday.new(@base) do |conn|
          conn.headers = {
            authorization: "Bearer #{@token}",
            accept: 'application/json, application/vnd.heliotrope.v1+json',
            content_type: 'application/json'
          }
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end
  end
end
