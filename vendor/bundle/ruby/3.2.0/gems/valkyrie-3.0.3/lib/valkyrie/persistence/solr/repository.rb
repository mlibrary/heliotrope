# frozen_string_literal: true
module Valkyrie::Persistence::Solr
  # Responsible for handling the logic for persisting or deleting multiple
  # objects into or out of solr.
  class Repository
    SOFT_COMMIT_PARAMS = { softCommit: true, versions: true }.freeze
    NO_COMMIT_PARAMS = { versions: true }.freeze

    attr_reader :resources, :persister
    delegate :connection, :resource_factory, :write_only?, :soft_commit?, to: :persister

    # @param [Array<Valkyrie::Resource>] resources
    # @param [RSolr::Client] connection
    # @param [ResourceFactory] resource_factory
    def initialize(resources:, persister:)
      @resources = resources
      @persister = persister
    end

    # Persist the resources into Solr
    # @return [Array<Valkyrie::Resource>]
    def persist
      documents = resources.map do |resource|
        generate_id(resource) if resource.id.blank?
        solr_document(resource)
      end
      results = add_documents(documents)
      return true if write_only?
      versions = results["adds"]&.each_slice(2)&.to_h
      documents.map do |document|
        document["_version_"] = versions.fetch(document[:id])
        resource_factory.to_resource(object: document.stringify_keys)
      end
    end

    # @param [Array<Hash>] array of Solr documents
    # @return [RSolr::HashWithResponse]
    # rubocop:disable Style/IfUnlessModifier
    def add_documents(documents)
      connection.add documents, params: commit_params
    rescue RSolr::Error::Http => exception
      # Error 409 conflict is returned when versions do not match
      if exception.response&.fetch(:status) == 409
        handle_conflict
      end
      raise exception
    end
    # rubocop:enable Style/IfUnlessModifier

    # Deletes a Solr Document using the ID
    # @return [Array<Valkyrie::Resource>] resources which have been deleted from Solr
    def delete
      connection.delete_by_id resources.map { |resource| resource.id.to_s }, params: commit_params
      resources
    end

    # Given a Valkyrie Resource, generate the Hash for the Solr Document
    # @param [Valkyrie::Resource] resource
    # @return [Hash]
    def solr_document(resource)
      resource_factory.from_resource(resource: resource).to_h
    end

    # Given a new Valkyrie Resource, generate a random UUID and assign it to the Resource
    # @param [Valkyrie::Resource] resource
    # @param [String] the UUID for the new resource
    # @see Valkyrie::Logging for details concerning log suppression.
    def generate_id(resource)
      Valkyrie.logger.warn("The Solr adapter is not meant to persist new resources, but is now generating an ID.", logging_context: "Valkyrie::Persistence::Solr::Repository#generate_id")
      resource.id = SecureRandom.uuid
    end

    # If a 409 conflict response is encountered when attempting to commit updates to Solr, raise a StaleObjectError
    # @see https://lucene.apache.org/solr/guide/updating-parts-of-documents.html#optimistic-concurrency
    # @see https://tools.ietf.org/html/rfc7231#section-6.5.8
    def handle_conflict
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process." if resources.count > 1
      raise Valkyrie::Persistence::StaleObjectError, "The object #{resources.first.id} has been updated by another process."
    end

    def commit_params
      if persister.soft_commit?
        SOFT_COMMIT_PARAMS
      else
        NO_COMMIT_PARAMS
      end
    end
  end
end
