# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for returning all {Valkyrie::Resource}s which are referenced in
  # a given {Valkyrie::Resource}'s property, in the order given in that property.
  class FindOrderedReferencesQuery
    attr_reader :resource, :property, :connection, :resource_factory
    def initialize(resource:, property:, connection:, resource_factory:)
      @resource = resource
      @property = property
      @connection = connection
      @resource_factory = resource_factory
    end

    def run
      enum_for(:each)
    end

    def each
      # map them off of the property to fix solr's deduplication
      property_values.map { |id| unordered_members.find { |member| member.id == id } } .reject(&:nil?).each do |value|
        yield value
      end
    end

    def unordered_members
      @unordered_members ||= docs.map do |doc|
        resource_factory.to_resource(object: doc)
      end
    end

    def docs
      options = { q: query, rows: 1_000_000_000 }
      options[:defType] = 'lucene'
      result = connection.get("select", params: options)
      result.fetch('response').fetch('docs')
    end

    def property_values
      Array.wrap(resource[property])
    end

    def query
      "{!join from=#{property}_ssim to=join_id_ssi}id:#{id}"
    end

    def id
      resource.id.to_s
    end
  end
end
