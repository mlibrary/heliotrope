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

  # Agent Validation

  def valid_email?(email)
    /.+\@.+\..+/.match?(email.to_s)
  end

  def valid_agent?(agent_type, agent_id)
    case agent_type
    when :email
      valid_email?(agent_id)
    when :institution
      Institution.find_by(identifier: agent_id.to_s).present?
    else
      false
    end
  end

  # Resource Validation

  def valid_noid?(noid)
    /^[[:alnum:]]{9}$/.match?(noid.to_s)
  end

  def valid_resource?(resource_type, resource_id)
    case resource_type
    when :noid
      valid_noid?(resource_id)
    when :product
      Product.find_by(identifier: resource_id.to_s).present?
    else
      false
    end
  end

  # Open Access a.k.a. any agent has permission:read for any resource

  def open_access?
    open_access_permit.present?
  end

  def permit_open_access
    return if open_access?
    agent = agent_factory.from(OpenStruct.new(agent_type: :any, agent_id: :any))
    resource = resource_factory.from(OpenStruct.new(resource_type: :any, resource_id: :any))
    permit = Checkpoint::DB::Permit.from(agent, permission_read, resource)
    permit.save
  end

  def revoke_open_access
    open_access_permit&.delete
  end

  # Open Access Resource a.k.a. any agent has permission:read for resource

  def open_access_resource?(resource_type, resource_id)
    open_access_resource_permit(resource_type: resource_type, resource_id: resource_id).present?
  end

  def permit_open_access_resource(resource_type, resource_id)
    return if open_access_resource?(resource_type, resource_id)
    return unless valid_resource?(resource_type, resource_id)
    agent = agent_factory.from(OpenStruct.new(agent_type: :any, agent_id: :any))
    resource = resource_factory.from(OpenStruct.new(resource_type: resource_type, resource_id: resource_id))
    permit = Checkpoint::DB::Permit.from(agent, permission_read, resource)
    permit.save
  end

  def revoke_open_access_resource(resource_type, resource_id)
    open_access_resource_permit(resource_type: resource_type, resource_id: resource_id)&.delete
  end

  # Read Access Resource a.k.a. agent has permission:read for resource

  def read_access_resource?(agent_type, agent_id, resource_type, resource_id)
    read_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id).present?
  end

  def permit_read_access_resource(agent_type, agent_id, resource_type, resource_id)
    return if read_access_resource?(agent_type, agent_id, resource_type, resource_id)
    return unless valid_agent?(agent_type, agent_id)
    return unless valid_resource?(resource_type, resource_id)
    agent = agent_factory.from(OpenStruct.new(agent_type: agent_type, agent_id: sanitize_agent_id(agent_id)))
    resource = resource_factory.from(OpenStruct.new(resource_type: resource_type, resource_id: resource_id))
    permit = Checkpoint::DB::Permit.from(agent, permission_read, resource)
    permit.save
  end

  def revoke_read_access_resource(agent_type, agent_id, resource_type, resource_id)
    read_access_resource_permit(agent_type: agent_type, agent_id: agent_id, resource_type: resource_type, resource_id: resource_id)&.delete
  end

  private

    def permission_read
      @permission_read ||= Checkpoint::Credential::Permission.new(:read)
    end

    def open_access_permit
      Checkpoint::DB::Permit.where(agent_type: 'any', agent_id: 'any', credential_type: permission_read.type, credential_id: permission_read.id, resource_type: 'any', resource_id: 'any').first
    end

    def open_access_resource_permit(resource_type:, resource_id:)
      return unless valid_resource?(resource_type, resource_id)
      Checkpoint::DB::Permit.where(agent_type: 'any', agent_id: 'any', credential_type: permission_read.type, credential_id: permission_read.id, resource_type: resource_type.to_s, resource_id: resource_id.to_s).first
    end

    def read_access_resource_permit(agent_type:, agent_id:, resource_type:, resource_id:)
      return unless valid_agent?(agent_type, agent_id)
      return unless valid_resource?(resource_type, resource_id)
      Checkpoint::DB::Permit.where(agent_type: agent_type.to_s, agent_id: sanitize_agent_id(agent_id).to_s, credential_type: permission_read.type, credential_id: permission_read.id, resource_type: resource_type.to_s, resource_id: resource_id.to_s).first
    end

    def sanitize_agent_id(agent_id)
      valid_email?(agent_id) ? agent_id.downcase : agent_id
    end

    attr_reader :agent_factory, :resource_factory
end
