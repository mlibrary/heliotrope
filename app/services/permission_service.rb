# frozen_string_literal: true

require 'ostruct'

class PermissionService
  # Class Methods

  # Needed only for rake tasks. Call it once and before any other method.
  def self.database_initialize!
    Checkpoint::DB.initialize!
  end

  def self.permits_table_empty?
    Checkpoint::DB.db[:permits].count.zero?
  end

  def self.clear_permits_table
    Checkpoint::DB.db[:permits].delete
  end

  # Instance Methods

  def initialize(agent_factory: Checkpoint::Agent, resource_factory: Checkpoint::Resource)
    @agent_factory = agent_factory
    @resource_factory = resource_factory
  end

  # Factories

  def agent(agent_type, agent_id)
    raise ArgumentError unless ValidationService.valid_agent_type?(agent_type)
    return OpenStruct.new(agent_type: agent_type, agent_id: agent_id) if agent_id&.to_s == 'any'
    raise ArgumentError unless ValidationService.valid_agent?(agent_type, agent_id)
    case agent_type&.to_sym
    when :Individual
      Individual.find(agent_id)
    when :Institution
      Institution.find(agent_id)
    else
      OpenStruct.new(agent_type: agent_type, agent_id: agent_id)
    end
  end

  def permission(permission)
    raise ArgumentError unless ValidationService.valid_permission?(permission)
    Checkpoint::Credential::Permission.new(permission)
  end

  def credential(credential_type, credential_id)
    raise ArgumentError unless ValidationService.valid_credential?(credential_type, credential_id)
    case credential_type&.to_sym
    when :permission
      permission(credential_id)
    else
      OpenStruct.new(credential_type: credential_type, credential_id: credential_id)
    end
  end

  def resource(resource_type, resource_id)
    raise ArgumentError unless ValidationService.valid_resource_type?(resource_type)
    return OpenStruct.new(resource_type: resource_type, resource_id: resource_id) if resource_id&.to_s == 'any'
    raise ArgumentError unless ValidationService.valid_resource?(resource_type, resource_id)
    case resource_type&.to_sym
    when :Component
      Component.find(resource_id)
    when :Product
      Product.find(resource_id)
    else
      OpenStruct.new(resource_type: resource_type, resource_id: resource_id)
    end
  end

  # Open Access a.k.a. any agent has permission:read for any resource

  def open_access?
    open_access_permit.present?
  end

  def permit_open_access
    return open_access_permit if open_access?
    actor = agent_factory.from(agent(:any, :any))
    target = resource_factory.from(resource(:any, :any))
    permit = Checkpoint::DB::Permit.from(actor, permission_read, target, zone: Checkpoint::DB::Permit.default_zone)
    permit.save
    permit
  end

  def revoke_open_access
    open_access_permit&.delete
  end

  # Open Access Resource a.k.a. any agent has permission:read for resource

  def open_access_resource?(resource_type, resource_id)
    open_access_resource_permit(resource_type: resource_type, resource_id: resource_id).present?
  end

  def permit_open_access_resource(resource_type, resource_id)
    return open_access_resource_permit(resource_type: resource_type, resource_id: resource_id) if open_access_resource?(resource_type, resource_id)
    actor = agent_factory.from(agent(:any, :any))
    target = resource_factory.from(resource(resource_type, resource_id))
    permit = Checkpoint::DB::Permit.from(actor, permission_read, target, zone: Checkpoint::DB::Permit.default_zone)
    permit.save
    permit
  end

  def revoke_open_access_resource(resource_type, resource_id)
    open_access_resource_permit(resource_type: resource_type, resource_id: resource_id)&.delete
  end

  # Read Access Resource a.k.a. agent has permission:read for resource

  def read_access_resource?(agent_type, agent_id, resource_type, resource_id)
    read_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id).present?
  end

  def permit_read_access_resource(agent_type, agent_id, resource_type, resource_id)
    return read_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id) if read_access_resource?(agent_type, agent_id, resource_type, resource_id)
    actor = agent_factory.from(agent(agent_type, agent_id))
    target = resource_factory.from(resource(resource_type, resource_id))
    permit = Checkpoint::DB::Permit.from(actor, permission_read, target, zone: Checkpoint::DB::Permit.default_zone)
    permit.save
    permit
  end

  def revoke_read_access_resource(agent_type, agent_id, resource_type, resource_id)
    read_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id)&.delete
  end

  # Any Access Resource a.k.a. agent has permission:any for resource

  def any_access_resource?(agent_type, agent_id, resource_type, resource_id)
    any_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id).present?
  end

  def permit_any_access_resource(agent_type, agent_id, resource_type, resource_id)
    return any_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id) if any_access_resource?(agent_type, agent_id, resource_type, resource_id)
    actor = agent_factory.from(agent(agent_type, agent_id))
    target = resource_factory.from(resource(resource_type, resource_id))
    permit = Checkpoint::DB::Permit.from(actor, permission_any, target, zone: Checkpoint::DB::Permit.default_zone)
    permit.save
    permit
  end

  def revoke_any_access_resource(agent_type, agent_id, resource_type, resource_id)
    any_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id)&.delete
  end

  private

    def permission_any
      @permission_any ||= Checkpoint::Credential::Permission.new(:any)
    end

    def permission_read
      @permission_read ||= Checkpoint::Credential::Permission.new(:read)
    end

    def open_access_permit
      actor = agent_factory.from(agent(:any, :any))
      target = resource_factory.from(resource(:any, :any))
      Checkpoint::DB::Permit.where(agent_type: actor.type, agent_id: actor.id,
                                   credential_type: permission_read.type, credential_id: permission_read.id,
                                   resource_type: target.type, resource_id: target.id).first
    end

    def open_access_resource_permit(resource_type:, resource_id:)
      raise(ArgumentError, 'invalid resource') unless ValidationService.valid_resource?(resource_type, resource_id)
      actor = agent_factory.from(agent(:any, :any))
      target = resource_factory.from(resource(resource_type, resource_id))
      Checkpoint::DB::Permit.where(agent_type: actor.type, agent_id: actor.id,
                                   credential_type: permission_read.type, credential_id: permission_read.id,
                                   resource_type: target.type, resource_id: target.id).first
    end

    def read_access_resource_permit(agent_type:, agent_id:, resource_type:, resource_id:)
      raise(ArgumentError, 'invalid agent') unless ValidationService.valid_agent?(agent_type, agent_id)
      raise(ArgumentError, 'invalid resource') unless ValidationService.valid_resource?(resource_type, resource_id)
      actor = agent_factory.from(agent(agent_type, agent_id))
      target = resource_factory.from(resource(resource_type, resource_id))
      Checkpoint::DB::Permit.where(agent_type: actor.type, agent_id: actor.id,
                                   credential_type: permission_read.type, credential_id: permission_read.id,
                                   resource_type: target.type, resource_id: target.id).first
    end

    def any_access_resource_permit(agent_type:, agent_id:, resource_type:, resource_id:)
      raise(ArgumentError, 'invalid agent') unless ValidationService.valid_agent?(agent_type, agent_id)
      raise(ArgumentError, 'invalid resource') unless ValidationService.valid_resource?(resource_type, resource_id)
      actor = agent_factory.from(agent(agent_type, agent_id))
      target = resource_factory.from(resource(resource_type, resource_id))
      Checkpoint::DB::Permit.where(agent_type: actor.type, agent_id: actor.id,
                                   credential_type: permission_any.type, credential_id: permission_any.id,
                                   resource_type: target.type, resource_id: target.id).first
    end

    attr_reader :agent_factory, :resource_factory
end
