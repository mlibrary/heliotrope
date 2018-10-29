# frozen_string_literal: true

require 'checkpoint/resource'
require 'ostruct'

# This resolver depends on the resource being a hash { noid: noid },
# from which key values are extracted and delivered as resources,
# as converted by the `resource_factory`.
class TargetResourceResolver < Checkpoint::Resource::Resolver
  def initialize(resource_factory: Checkpoint::Resource)
    @resource_factory = resource_factory
  end

  def resolve(target)
    resources = []
    resources << resource_factory.from(OpenStruct.new(resource_type: :any, resource_id: :any)) # All targets
    handle = NoidService.from_noid(target[:noid])
    if handle.valid?
      resources << resource_factory.from(OpenStruct.new(resource_type: :noid, resource_id: handle.noid))
      component = Component.find_by(noid: handle.noid)
      if component.present?
        resources << resource_factory.from(component)
        component.products.each do |product|
          resources << resource_factory.from(product)
        end
      end
    end
    resources
  end

  private

    attr_reader :resource_factory
end
