# frozen_string_literal: true
module Valkyrie
  # MetadataAdapter is the primary DataMapper object for metadata persistence.
  #  Used to register and locate adapters, persisters, and query services for individual
  #  metadata storage backends (such as fedora, postgres, etc)
  class MetadataAdapter
    class_attribute :adapters
    self.adapters = {}
    class << self
      # Register an adapter by a short name.
      # Registering an adapter by a short name makes the adapter easier to find and reference.
      # @param adapter [#persister,#query_service] Adapter to register.
      # @param short_name [Symbol] Name to register it under.
      def register(adapter, short_name)
        adapters[short_name.to_sym] = adapter
      end

      # Find an adapter by its short name.
      # @param short_name [Symbol]
      # @return [#persister,#query_service]
      # @raise RuntimeError when the given short_name is not found amongst the registered adapters
      def find(short_name)
        symbolized_key = short_name.to_sym
        return adapters[symbolized_key] if adapters.key?(symbolized_key)
        raise "Unable to find unregistered adapter `#{short_name}'"
      end

      # @api public
      # @since 0.1.0
      # Find the persister registered under the given short-name
      #
      # @param short_name [Symbol]
      # @return [Object] an object that behaves like "a Valkyrie::Persister"
      # @see GEM_ROOT/lib/valkyrie/specs/shared_specs/persister.rb
      def find_persister_for(short_name)
        find(short_name).persister
      end

      # @api public
      # @since 0.1.0
      # Find the query service registered under the given short-name
      #
      # @param short_name [Symbol]
      # @return [Object] an object that behaves like "a Valkyrie query provider"
      # @see GEM_ROOT/lib/valkyrie/specs/shared_specs/queries.rb
      def find_query_service_for(short_name)
        find(short_name).query_service
      end
    end
  end
end
