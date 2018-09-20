# frozen_string_literal: true

class Permit < Checkpoint::DB::Permit
  include ActiveModel::Model

  validates_each Permit.columns do |record, attr, value|
    next if attr == :id
    record.errors.add attr, 'must be present.' if value.blank?
  end

  def self.create!(attributes)
    permit = Permit.new
    permit.set(attributes)
    permit.save!
  end

  def self.create(attributes)
    permit = Permit.create!(attributes)
  rescue Sequel::ValidationFailed
    permit
  end

  def save!(opts = {})
    method(:save).super_method.call(opts)
  end

  def save(opts = {})
    save!(opts)
  rescue Sequel::ValidationFailed
    false
  end

  def update!(attributes)
    set(attributes)
    save_changes != false
  end

  def update(attributes)
    update!(attributes)
  rescue Sequel::ValidationFailed
    false
  end

  def persisted?
    !id.nil?
  end
end
