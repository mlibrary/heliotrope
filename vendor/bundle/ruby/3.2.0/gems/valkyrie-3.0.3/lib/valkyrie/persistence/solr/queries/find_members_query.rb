# frozen_string_literal: true
module Valkyrie::Persistence::Solr::Queries
  # Responsible for returning all members of a given resource as
  # {Valkyrie::Resource}s
  class FindMembersQuery
    attr_reader :resource, :connection, :resource_factory, :model

    # @param [Valkyrie::Resource] resource
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    # @param [Class] model
    def initialize(resource:, connection:, resource_factory:, model:)
      @resource = resource
      @connection = connection
      @resource_factory = resource_factory
      @model = model
    end

    # Iterate over each Solr Document and convert each Document into a Valkyrie Resource
    # @return [Array<Valkyrie::Resource>]
    def run
      enum_for(:each)
    end

    # Queries for all member Documents in the Solr index
    # For each Document, it yields the Valkyrie Resource which was converted from it
    # Results are ordered by the member IDs specified in the Valkyrie Resource attribute
    # @yield [Valkyrie::Resource]
    def each
      return [] if resource.id.blank?
      member_ids.map { |id| unordered_members.find { |member| member.id == id } }.reject(&:nil?).each do |member|
        yield member
      end
    end

    # Retrieving the Solr Documents for the member resources, construct Valkyrie Resources for each
    # @return [Array<Valkyrie::Resource>]
    def unordered_members
      @unordered_members ||= docs.map do |doc|
        resource_factory.to_resource(object: doc)
      end
    end

    # Query Solr for all members of the Valkyrie Resource
    # If a model is specified, this is used to filter the results
    # @return [Array<Hash>]
    def docs
      options = { q: query, rows: 1_000_000_000 }
      options[:fq] = "{!raw f=internal_resource_ssim}#{model}" if model
      options[:defType] = 'lucene'
      result = connection.get("select", params: options)
      result["response"]["docs"]
    end

    # Access the IDs of the members for the Valkyrie Resource
    # @return [Array<Valkyrie::ID>]
    def member_ids
      resource.respond_to?(:member_ids) ? Array.wrap(resource.member_ids) : []
    end

    # Generate the Solr join query using the id_ssi field
    # @see https://lucene.apache.org/solr/guide/other-parsers.html#join-query-parser
    # @return [String]
    def query
      "{!join from=#{MEMBER_IDS} to=join_id_ssi}id:#{id}"
    end

    # Retrieve the string value for the ID
    # @return [String]
    def id
      resource.id.to_s
    end
  end
end
