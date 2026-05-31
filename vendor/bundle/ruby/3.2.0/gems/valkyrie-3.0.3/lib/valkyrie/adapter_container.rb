# frozen_string_literal: true
module Valkyrie
  class AdapterContainer
    # Wraps up an individual persister and query service to conform to the
    # adapter interface. Useful for decorated persisters.
    attr_reader :persister, :query_service
    def initialize(persister:, query_service:)
      @persister = persister
      @query_service = query_service
    end
  end
end
