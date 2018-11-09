# frozen_string_literal: true

class Grant
  include ActiveModel::Model

  attr_reader :permit

  attr_accessor :agent_user_id, :agent_individual_id, :agent_institution_id
  attr_accessor :credential_permission_id
  attr_accessor :resource_noid_id, :resource_component_id, :resource_product_id

  COLUMNS = %i[agent_type agent_id credential_type credential_id resource_type resource_id].freeze

  delegate :agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id, to: :@permit

  validates_each COLUMNS do |record, attr, value|
    record.errors.add attr, 'must be present.' if value.blank?
    case attr
    when :agent_type
      record.errors.add attr, 'invalid type.' unless ValidationService.valid_agent_type?(value)
    when :agent_id
      if ValidationService.valid_agent_type?(record.agent_type)
        record.errors.add attr, 'invalid value.' unless ValidationService.valid_agent?(record.agent_type, value)
      end
    when :credential_type
      record.errors.add attr, 'invalid type.' unless %i[permission].include?(value&.to_sym)
    when :credential_id
      record.errors.add attr, 'invalid value.' unless %i[any read].include?(value&.to_sym)
    when :resource_type
      record.errors.add attr, 'invalid type.' unless ValidationService.valid_resource_type?(value)
    when :resource_id
      if ValidationService.valid_resource_type?(record.resource_type)
        record.errors.add attr, 'invalid value.' unless ValidationService.valid_resource?(record.resource_type, value)
      end
    end
  end

  def self.create!(attributes)
    grant = new
    grant.set(attributes)
    raise Sequel::ValidationFailed if grant.invalid?
    grant.save!
    grant
  end

  def self.create(attributes)
    grant = create!(attributes)
  rescue Sequel::ValidationFailed
    grant
  end

  def self.count
    Checkpoint::DB::Permit.count
  end

  def self.last
    new(Checkpoint::DB::Permit.last)
  end

  def self.agent_grants(entity)
    agent = Checkpoint::Agent.new(entity)
    Checkpoint::DB::Permit.where(agent_token: agent.token.to_s).map { |permit| Grant.new(permit) }
  end

  def self.permission_grants(permission)
    permission = PermissionService.permission(permission)
    Checkpoint::DB::Permit.where(credential_token: permission.token.to_s).map { |permit| Grant.new(permit) }
  end

  def self.resource_grants(entity)
    resource = Checkpoint::Resource.new(entity)
    Checkpoint::DB::Permit.where(resource_token: resource.token.to_s).map { |permit| Grant.new(permit) }
  end

  def initialize(permit = Checkpoint::DB::Permit.new)
    @permit = permit
  end

  def set(attributes = {})
    @permit.set(attributes)
  end

  def save!(opts = {})
    @permit.save(opts) if valid?
  end

  def save(opts = {})
    save!(opts)
  end

  def destroy
    @permit.delete
  end

  def reload
    @permit.reload
  end

  def id
    @permit&.id
  end

  def persisted?
    id.present?
  end

  def update?
    false
  end

  def destroy?
    true
  end
end
