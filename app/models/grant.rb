# frozen_string_literal: true

class Grant
  include ActiveModel::Model

  attr_reader :permit

  attr_accessor :agent_user_id, :agent_individual_id, :agent_institution_id
  attr_accessor :credential_permission_id
  attr_accessor :resource_noid_id, :resource_component_id, :resource_product_id

  COLUMNS = %i[agent_type agent_id credential_type credential_id resource_type resource_id].freeze

  delegate :agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id, to: :@permit
  delegate :agent_type=, :agent_id=, :agent_token=, :credential_type=, :credential_id=, :credential_token=, :resource_type=, :resource_id=, :resource_token=, :zone_id=, to: :@permit

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

  def self.find(id)
    permit = Checkpoint::DB::Permit.find(id: id)
    return nil if permit.blank?
    new(permit)
  end

  def self.find_by(agent_token:, credential_token:, resource_token:)
    permit = Checkpoint::DB::Permit.where(agent_token: agent_token, credential_token: credential_token, resource_token: resource_token).first # rubocop:disable Rails/FindBy
    return nil if permit.blank?
    new(permit)
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
    token = "#{agent.type}:#{agent.id}"
    Checkpoint::DB::Permit.where(agent_token: token).map { |permit| Grant.new(permit) }
  end

  def self.permission_grants(permission)
    permission = PermissionService.permission(permission)
    token = "#{permission.type}:#{permission.id}"
    Checkpoint::DB::Permit.where(credential_token: token).map { |permit| Grant.new(permit) }
  end

  def self.resource_grants(entity)
    resource = Checkpoint::Resource.new(entity)
    token = "#{resource.type}:#{resource.id}"
    Checkpoint::DB::Permit.where(resource_token: token).map { |permit| Grant.new(permit) }
  end

  def initialize(permit = Checkpoint::DB::Permit.new)
    @permit = permit
  end

  def set(attributes = {})
    @permit.set(attributes)
  end

  def save!(opts = {})
    @permit.save(opts) if valid? && unique?
  end

  def save(opts = {})
    save!(opts)
  end

  def destroy!
    @permit.delete
  end

  def destroy
    destroy!
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

  def unique?
    unique.blank?
  end

  def unique
    permit = Checkpoint::DB::Permit.where(
      agent_type: agent_type.to_s,
      agent_id: agent_id.to_s,
      agent_token: agent_token.to_s,
      credential_type: credential_type.to_s,
      credential_id: credential_id.to_s,
      credential_token: credential_token.to_s,
      resource_type: resource_type.to_s,
      resource_id: resource_id.to_s,
      resource_token: resource_token.to_s,
      zone_id: zone_id.to_s
    )
    permit = permit.first
    return nil if permit.blank?
    Grant.new(permit)
  end
end
