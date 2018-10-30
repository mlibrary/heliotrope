# frozen_string_literal: true

class Policy
  include ActiveModel::Model

  COLUMNS = %i[agent_type agent_id credential_type credential_id resource_type resource_id].freeze

  delegate :agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id, to: :@permit

  validates_each COLUMNS do |record, attr, value|
    record.errors.add attr, 'must be present.' if value.blank?
    case attr
    when :agent_type
      record.errors.add attr, 'invalid type.' unless PermissionService.new.valid_agent_type?(value)
    when :agent_id
      if PermissionService.new.valid_agent_type?(record.agent_type)
        record.errors.add attr, 'invalid value.' unless PermissionService.new.valid_agent?(record.agent_type, value)
      end
    when :credential_type
      record.errors.add attr, 'invalid type.' unless %i[permission].include?(value&.to_sym)
    when :credential_id
      record.errors.add attr, 'invalid value.' unless %i[read].include?(value&.to_sym)
    when :resource_type
      record.errors.add attr, 'invalid type.' unless PermissionService.new.valid_resource_type?(value)
    when :resource_id
      if PermissionService.new.valid_resource_type?(record.resource_type)
        record.errors.add attr, 'invalid value.' unless PermissionService.new.valid_resource?(record.resource_type, value)
      end
    end
  end

  def self.create!(attributes)
    policy = new
    policy.set(attributes)
    raise Sequel::ValidationFailed if policy.invalid?
    policy.save!
    policy
  end

  def self.create(attributes)
    policy = create!(attributes)
  rescue Sequel::ValidationFailed
    policy
  end

  def self.count
    Checkpoint::DB::Permit.count
  end

  def self.last
    new(Checkpoint::DB::Permit.last)
  end

  def self.agent_policies(entity)
    agent = Checkpoint::Agent.from(entity)
    Checkpoint::DB::Permit.where(agent_token: agent.token.to_s).map { |permit| Policy.new(permit) }
  end

  def self.credential_policies(entity)
    credential = Checkpoint::Credential.from(entity)
    Checkpoint::DB::Permit.where(credential_token: credential.token.to_s).map { |permit| Policy.new(permit) }
  end

  def self.resource_policies(entity)
    resource = Checkpoint::Resource.from(entity)
    Checkpoint::DB::Permit.where(resource_token: resource.token.to_s).map { |permit| Policy.new(permit) }
  end

  def initialize(permit = Checkpoint::DB::Permit.new)
    @permit = permit
  end

  def set(attributes = {})
    @permit.set(attributes)
  end

  def save!(opts = {})
    @permit.save(opts)
  end

  def save(opts = {})
    save!(opts)
  rescue Sequel::ValidationFailed
    false
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

  def agent
    @agent ||= case agent_type
               when 'Individual'
                 Individual.find(agent_id)
               when 'Institution'
                 Institution.find(agent_id)
               else
                 Entity.new(agent_type, agent_id, type: :any, id: :any)
               end
  end

  def resource
    @resource ||= case resource_type
                  when 'Component'
                    Component.find(resource_id)
                  when 'Product'
                    Product.find(resource_id)
                  else
                    Entity.new(resource_type, resource_id, type: :any, id: :any)
                  end
  end
end
