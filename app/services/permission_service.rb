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

  # Factories

  def self.agent(agent_type, agent_id) # rubocop:disable Metrics/CyclomaticComplexity
    raise ArgumentError unless ValidationService.valid_agent_type?(agent_type)
    return OpenStruct.new(agent_type: agent_type, agent_id: agent_id) if agent_id&.to_s == 'any'
    raise ArgumentError unless ValidationService.valid_agent?(agent_type, agent_id)
    case agent_type&.to_s&.to_sym
    when :Guest
      User.guest(user_key: agent_id)
    when :Individual
      Individual.find(agent_id)
    when :Institution
      Institution.find(agent_id)
    when :User
      User.find(agent_id)
    else
      OpenStruct.new(agent_type: agent_type, agent_id: agent_id)
    end
  end

  def self.permission(permission)
    raise ArgumentError unless ValidationService.valid_permission?(permission)
    Checkpoint::Credential::Permission.new(permission)
  end

  def self.credential(credential_type, credential_id)
    raise ArgumentError unless ValidationService.valid_credential?(credential_type, credential_id)
    case credential_type&.to_sym
    when :permission
      permission(credential_id)
    else
      OpenStruct.new(credential_type: credential_type, credential_id: credential_id)
    end
  end

  def self.resource(resource_type, resource_id) # rubocop:disable Metrics/CyclomaticComplexity
    raise ArgumentError unless ValidationService.valid_resource_type?(resource_type)
    return OpenStruct.new(resource_type: resource_type, resource_id: resource_id) if resource_id&.to_s == 'any'
    raise ArgumentError unless ValidationService.valid_resource?(resource_type, resource_id)
    case resource_type&.to_s&.to_sym
    when :ElectronicPublication
      Sighrax.factory(resource_id)
    when :Component
      Component.find(resource_id)
    when :Product
      Product.find(resource_id)
    else
      OpenStruct.new(resource_type: resource_type, resource_id: resource_id)
    end
  end

  # Open Access a.k.a. any agent has permission:read for any resource

  def self.open_access?
    actor = agent(:any, :any)
    target = resource(:any, :any)
    permit?(actor, permission_read, target)
  end

  def self.permit_open_access
    actor = agent(:any, :any)
    target = resource(:any, :any)
    authority.permit!(actor, permission_read, target) unless permit?(actor, permission_read, target)
    permit(actor, permission_read, target)
  end

  def self.revoke_open_access
    actor = agent(:any, :any)
    target = resource(:any, :any)
    authority.revoke!(actor, permission_read, target) if permit?(actor, permission_read, target)
  end

  # Open Access Resource a.k.a. any agent has permission:read for resource

  def self.open_access_resource?(resource_type, resource_id)
    actor = agent(:any, :any)
    target = resource(resource_type, resource_id)
    permit?(actor, permission_read, target)
  end

  def self.permit_open_access_resource(resource_type, resource_id)
    actor = agent(:any, :any)
    target = resource(resource_type, resource_id)
    authority.permit!(actor, permission_read, target) unless permit?(actor, permission_read, target)
    permit(actor, permission_read, target)
  end

  def self.revoke_open_access_resource(resource_type, resource_id)
    actor = agent(:any, :any)
    target = resource(resource_type, resource_id)
    authority.revoke!(actor, permission_read, target) if permit?(actor, permission_read, target)
  end

  # Read Access Resource a.k.a. agent has permission:read for resource

  def self.read_access_resource?(agent_type, agent_id, resource_type, resource_id)
    actor = agent(agent_type, agent_id)
    target = resource(resource_type, resource_id)
    permit?(actor, permission_read, target)
  end

  def self.permit_read_access_resource(agent_type, agent_id, resource_type, resource_id)
    actor = agent(agent_type, agent_id)
    target = resource(resource_type, resource_id)
    authority.permit!(actor, permission_read, target) unless permit?(actor, permission_read, target)
    permit(actor, permission_read, target)
  end

  def self.revoke_read_access_resource(agent_type, agent_id, resource_type, resource_id)
    actor = agent(agent_type, agent_id)
    target = resource(resource_type, resource_id)
    authority.revoke!(actor, permission_read, target) if permit?(actor, permission_read, target)
  end

  # Any Access Resource a.k.a. agent has permission:any for resource

  def self.any_access_resource?(agent_type, agent_id, resource_type, resource_id)
    actor = agent(agent_type, agent_id)
    target = resource(resource_type, resource_id)
    permit?(actor, permission_any, target)
  end

  def self.permit_any_access_resource(agent_type, agent_id, resource_type, resource_id)
    actor = agent(agent_type, agent_id)
    target = resource(resource_type, resource_id)
    authority.permit!(actor, permission_any, target) unless permit?(actor, permission_any, target)
    permit(actor, permission_any, target)
  end

  def self.revoke_any_access_resource(agent_type, agent_id, resource_type, resource_id)
    actor = agent(agent_type, agent_id)
    target = resource(resource_type, resource_id)
    authority.revoke!(actor, permission_any, target) if permit?(actor, permission_any, target)
  end

  def self.permission_any
    @permission_any ||= Checkpoint::Credential::Permission.new(:any)
  end

  def self.permission_read
    @permission_read ||= Checkpoint::Credential::Permission.new(:read)
  end

  def self.authority
    Services.checkpoint
  end

  def self.permit?(actor, action, target)
    permit(actor, action, target).present?
  end

  def self.permit(actor, action, target)
    converted_actor = ActorAgentResolver.new.convert(actor)
    converted_action = Checkpoint::Credential::Resolver.new.convert(action)
    converted_target = TargetResourceResolver.new.convert(target)
    record = Checkpoint::DB::Permit.where(agent_type: converted_actor.type, agent_id: converted_actor.id,
                                          credential_type: converted_action.type, credential_id: converted_action.id,
                                          resource_type: converted_target.type, resource_id: converted_target.id).first
    record
  end
end
