# frozen_string_literal: true

module Yabeda
  module HttpRequests
    # Middleware for sniffer gem
    class Sniffer
      def request(data_item)
        yield
        Yabeda.http_request_total.increment(
          {
            host: data_item.request.host,
            port: data_item.request.port,
            method: data_item.request.method.upcase
          }
        )
      end

      def response(data_item)
        yield
        log_http_response_total(data_item)
        log_http_response_duration(data_item)
      end

      private

      def log_http_response_total(data_item)
        Yabeda.http_response_total.increment(
          {
            host: data_item.request.host,
            port: data_item.request.port,
            method: data_item.request.method.upcase,
            status: data_item.response.status
          }
        )
      end

      def log_http_response_duration(data_item)
        labels = {
          host: data_item.request.host,
          port: data_item.request.port,
          method: data_item.request.method.upcase,
          status: data_item.response.status
        }

        Yabeda.http_response_duration.measure(
          labels, duration_in_milliseconds(data_item)
        )
      end

      def duration_in_milliseconds(data_item)
        seconds = data_item.response&.timing
        return nil if seconds.nil?

        (seconds * 1000).round
      end
    end
  end
end
