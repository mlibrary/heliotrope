# frozen_string_literal: true

module Valkyrie::Persistence
  # Allows for implementors to register and use custom queries on a
  #  per persister basis
  #
  # @example Custom Query Class
  #
  #     # Snippet from custom query class see: https://github.com/pulibrary/figgy/blob/d0b1305a1564c2aa4e7d6c1e99f0c2a88ed673f4/app/queries/find_by_string_property.rb
  #     class FindByStringProperty
  #       def self.queries
  #         [:find_by_string_property]
  #       end
  #
  #       ...
  #
  #       def initialize(query_service:)
  #         @query_service = query_service
  #       end
  #       ...
  #
  #       def find_by_string_property(property:, value:)
  #         internal_array = "{\"#{property}\": [\"#{value}\"]}"
  #         run_query(query, internal_array)
  #       end
  #       ...
  #     end
  #
  # @example Registration
  #
  #   # in config/initializers/valkyrie.rb
  #   [FindByStringProperty].each do |query_handler|
  #     Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
  #   end
  #
  # @see lib/valkyrie/persistence/solr/query_service.rb for use of this class
  #
  class CustomQueryContainer
    attr_reader :query_service, :query_handlers
    def initialize(query_service:)
      @query_service = query_service
      @query_handlers = {}
    end

    def register_query_handler(query_handler)
      query_handler.queries.each do |query|
        handler = query_handler.new(query_service: query_service)
        query_handlers[query.to_sym] = handler
        define_singleton_method query do |*args, **kwargs, &block|
          if kwargs.empty?
            # This case needs to be specially handled in Ruby 2.6, or else an
            # empty hash will be passed as the final argument.
            query_handlers[query.to_sym].__send__(query, *args, &block)
          else
            query_handlers[query.to_sym].__send__(query, *args, **kwargs, &block)
          end
        end
      end
    end
  end
end
