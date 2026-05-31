# frozen_string_literal: true

require 'yabeda/http_requests/version'
require 'yabeda/http_requests/sniffer'
require 'yabeda'
require 'sniffer'

module Yabeda
  # Common module
  module HttpRequests
    SNIFFER_STORAGE_SIZE = 0

    LONG_RUNNING_REQUEST_BUCKETS = [
      0.5, 1, 2.5, 5, 10, 25, 50, 100, 250, 500, 1000, # standard
      30_000, 60_000, 120_000, 300_000, 600_000 # slow queries
    ].freeze

    Yabeda.configure do
      group :http

      counter :request_total,
              comment: 'A counter of the total number of external HTTP \
                         requests.',
              tags: %i[host port method]
      counter :response_total,
              comment: 'A counter of the total number of external HTTP \
                         responses.',
              tags: %i[host port method status]

      histogram :response_duration, tags: %i[host port method status],
                                    unit: :milliseconds,
                                    buckets: LONG_RUNNING_REQUEST_BUCKETS,
                                    comment: "A histogram of the response \
                                               duration (milliseconds)."

      ::Sniffer.config do |c|
        c.enabled = true
        c.store = { capacity: SNIFFER_STORAGE_SIZE }
        c.middleware do |chain|
          chain.remove(::Sniffer::Middleware::Logger)
          chain.add(Yabeda::HttpRequests::Sniffer)
        end
      end
    end
  end
end
