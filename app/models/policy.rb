# frozen_string_literal: true

class Policy
  include ActiveModel::Model

  COLUMNS = %i[id agent_type agent_id agent_token credential_type credential_id credential_token resource_type resource_id resource_token zone_id].freeze

  delegate :agent_type, :agent_id, :agent_token, :credential_type, :credential_id, :credential_token, :resource_type, :resource_id, :resource_token, :zone_id, to: :@permit

  validates_each COLUMNS do |record, attr, value|
    next if attr == :id
    record.errors.add attr, 'must be present.' if value.blank?
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

  def update!(attributes)
    @permit.set(attributes)
    raise Sequel::ValidationFailed if invalid?
    @permit.save_changes != false
  end

  def update(attributes)
    update!(attributes)
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
end
