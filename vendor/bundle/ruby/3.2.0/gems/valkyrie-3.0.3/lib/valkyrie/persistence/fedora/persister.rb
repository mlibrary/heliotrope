# frozen_string_literal: true
module Valkyrie::Persistence::Fedora
  # Persister for Fedora MetadataAdapter.
  class Persister
    require 'valkyrie/persistence/fedora/persister/resource_factory'
    require 'valkyrie/persistence/fedora/persister/alternate_identifier'
    attr_reader :adapter
    delegate :connection, :base_path, :resource_factory, to: :adapter

    # @note (see Valkyrie::Persistence::Memory::Persister#initialize)
    def initialize(adapter:)
      @adapter = adapter
    end

    # (see Valkyrie::Persistence::Memory::Persister#save)
    def save(resource:, external_resource: false)
      initialize_repository
      internal_resource = resource.dup
      internal_resource.created_at ||= Time.current
      internal_resource.updated_at = Time.current
      validate_lock_token(internal_resource)
      native_lock = native_lock_token(internal_resource)
      generate_lock_token(internal_resource)
      orm = resource_factory.from_resource(resource: internal_resource)
      alternate_resources = find_or_create_alternate_ids(internal_resource)

      if !orm.new? || internal_resource.id
        cleanup_alternate_resources(internal_resource) if alternate_resources
        orm.update { |req| update_request_headers(req, native_lock) }
      else
        orm.create
      end
      persisted_resource = resource_factory.to_resource(object: orm)

      alternate_resources ? save_reference_to_resource(persisted_resource, alternate_resources) : persisted_resource
    rescue Ldp::PreconditionFailed
      raise Valkyrie::Persistence::StaleObjectError, "The object #{internal_resource.id} has been updated by another process."
    rescue Ldp::Gone
      raise Valkyrie::Persistence::ObjectNotFoundError, "The object #{resource.id} is previously persisted but not found at save time."
    end

    # (see Valkyrie::Persistence::Memory::Persister#save_all)
    def save_all(resources:)
      resources.map do |resource|
        save(resource: resource)
      end
    rescue Valkyrie::Persistence::StaleObjectError
      # blank out the message / id
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
    end

    # (see Valkyrie::Persistence::Memory::Persister#delete)
    def delete(resource:)
      if resource.try(:alternate_ids)
        resource.alternate_ids.each do |alternate_identifier|
          adapter.persister.delete(resource: adapter.query_service.find_by(id: alternate_identifier))
        end
      end

      orm = resource_factory.from_resource(resource: resource)
      orm.delete

      resource
    end

    # (see Valkyrie::Persistence::Memory::Persister#wipe!)
    # Deletes Fedora repository resource *and* the tombstone resources which remain
    # @see https://wiki.duraspace.org/display/FEDORA4x/RESTful+HTTP+API#RESTfulHTTPAPI-RedDELETEDeletearesource
    # @see Valkyrie::Logging for details concerning log suppression.
    def wipe!
      connection.delete(base_path)
      connection.delete("#{base_path}/fcr:tombstone")
    rescue => error
      Valkyrie.logger.debug("Failed to wipe Fedora for some reason: #{error}", logging_context: "Valkyrie::Persistence::Fedora::Persister#wipe") unless error.is_a?(::Ldp::NotFound)
    end

    # Creates the root LDP Container for the connection with Fedora
    # @see https://www.w3.org/TR/ldp/#ldpc
    # @return [Ldp::Container::Basic]
    def initialize_repository
      @initialized ||=
        begin
          resource = ::Ldp::Container::Basic.new(connection, base_path, nil, base_path)
          resource.save if resource.new?
          true
        end
    end

    private

    # Ensure that all alternate IDs for a given resource are persisted
    # @param [Valkyrie::Resource] resource
    # @return [Array<Valkyrie::Persistence::Fedora::AlternateIdentifier>]
    def find_or_create_alternate_ids(resource)
      return nil unless resource.try(:alternate_ids)

      resource.alternate_ids.map do |alternate_identifier|
        adapter.query_service.find_by(id: alternate_identifier)
      rescue ::Valkyrie::Persistence::ObjectNotFoundError
        alternate_resource = ::Valkyrie::Persistence::Fedora::AlternateIdentifier.new(id: alternate_identifier)
        adapter.persister.save(resource: alternate_resource)
      end
    end

    # Ensure that any Resources referenced by alternate IDs are deleted when a Resource has these IDs deleted
    # @param [Valkyrie::Resource] updated_resource
    def cleanup_alternate_resources(updated_resource)
      persisted_resource = adapter.query_service.find_by(id: updated_resource.id)
      removed_identifiers = persisted_resource.alternate_ids - updated_resource.alternate_ids

      removed_identifiers.each do |removed_id|
        adapter.persister.delete(resource: adapter.query_service.find_by(id: removed_id))
      end
    end

    # Ensure that any Resources referenced by alternate IDs are persisted when a Resource has these IDs added
    # @param [Valkyrie::Resource] resource
    # @param [Array<Valkyrie::Persistence::Fedora::AlternateIdentifier>] alternate_resources
    # @return [Valkyrie::Resource]
    def save_reference_to_resource(resource, alternate_resources)
      alternate_resources.each do |alternate_resource|
        alternate_resource.references = resource.id
        adapter.persister.save(resource: alternate_resource)
      end

      resource
    end

    # Generate the lock token for a Resource, and set it for attribute
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Persistence::OptimisticLockToken]
    # @see https://github.com/samvera-labs/valkyrie/wiki/Optimistic-Locking
    # @note Fedora's last modified response is not granular enough to produce an effective lock token
    #   therefore, we use the same implementation as the memory adapter. This could fail to lock a
    #   resource if Fedora updated this resource between the time it was saved and Valkyrie created
    #   the token.
    def generate_lock_token(resource)
      return unless resource.optimistic_locking_enabled?
      token = Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: adapter.id, token: Time.now.to_r)
      resource.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", token)
    end

    # Determine whether or not a lock token is still valid for a persisted Resource
    #   If the persisted Resource has been updated since it was last read into memory,
    #   then the resouce in memory has been invalidated and Valkyrie::Persistence::StaleObjectError
    #   is raised.
    # @param [Valkyrie::Resource] resource
    # @see https://github.com/samvera-labs/valkyrie/wiki/Optimistic-Locking
    # @raise [Valkyrie::Persistence::StaleObjectError]
    def validate_lock_token(resource)
      return unless resource.optimistic_locking_enabled?
      return if resource.id.blank?

      current_lock_token = resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].find { |lock_token| lock_token.adapter_id == adapter.id }
      return if current_lock_token.blank?

      retrieved_lock_tokens = adapter.query_service.find_by(id: resource.id)[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
      retrieved_lock_token = retrieved_lock_tokens.find { |lock_token| lock_token.adapter_id == adapter.id }
      return if retrieved_lock_token.blank?

      raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." unless current_lock_token == retrieved_lock_token
    end

    # Retrieve the lock token that holds Fedora's system-managed last-modified date
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Persistence::OptimisticLockToken]
    def native_lock_token(resource)
      return unless resource.optimistic_locking_enabled?
      resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].find { |lock_token| lock_token.adapter_id.to_s == "native-#{adapter.id}" }
    end

    # Set Fedora request headers:
    # * `Prefer: handling=lenient; received="minimal"` allows us to avoid sending all server-managed triples
    # * `If-Unmodified-Since` triggers Fedora's server-side optimistic locking
    # @param request [Faraday::Request]
    # @param lock_token [Valkyrie::Persistence::OptimisticLockToken]
    def update_request_headers(request, lock_token)
      request.headers["Prefer"] = "handling=lenient; received=\"minimal\""
      request.headers["If-Unmodified-Since"] = lock_token.token if lock_token
    end
  end
end
