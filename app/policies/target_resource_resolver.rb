# frozen_string_literal: true

require 'checkpoint/resource'
require 'ostruct'

# This resolver depends on the resource being a hash { noid: noid, products: [products] },
# from which key values are extracted and delivered as resources,
# as converted by the `resource_factory`.
class TargetResourceResolver < Checkpoint::Resource::Resolver
  def initialize(resource_factory: Checkpoint::Resource)
    @resource_factory = resource_factory
  end

  def resolve(target)
    resources = []
    resources << resource_factory.from(OpenStruct.new(resource_type: :any, resource_id: :any)) # All targets
    resources << resource_factory.from(OpenStruct.new(resource_type: :noid, resource_id: target[:noid])) if target[:noid].present?
    (target[:products] || []).map do |product|
      resources << resource_factory.from(OpenStruct.new(resource_type: :product, resource_id: product.identifier))
    end
    resources
  end

  private

    attr_reader :resource_factory
end
