# frozen_string_literal: true

class PolicyResource
  def initialize(resource_class, resource = nil)
    @resource_class = resource_class
    @resource = resource
  end

  def resource_type
    @resource_class.name.downcase
  end

  def resource_id
    return Checkpoint::Resource::AllOfType.new(resource_type).id if @resource.nil?
    @resource.id
  end
end
