# frozen_string_literal: true

class PolicyResource
  def initialize(resource_class, resource = nil)
    @resource_class = resource_class
    @resource = resource
  end

  def resource_type
    @resource_class.name.downcase
  end

  def type
    resource_type
  end

  def resource_id
    return Checkpoint::Resource::AllOfType.new(resource_type).id if @resource.nil?
    @resource.id
  end

  def id
    resource_id
  end

  def token
    Checkpoint::Resource::Token.new(type, id)
  end

  def entity
    @resource || @resource_class
  end
end
