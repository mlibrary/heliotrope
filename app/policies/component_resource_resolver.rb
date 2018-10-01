# frozen_string_literal: true

require 'checkpoint/resource'
require 'ostruct'

# This resolver depends on the resource having the `#products` method,
# from which all products are extracted and delivered as resources,
# as converted by the `resource_factory`.
class ComponentResourceResolver < Checkpoint::Resource::Resolver
  def initialize(resource_factory: Checkpoint::Resource)
    @resource_factory = resource_factory
  end

  def resolve(target)
    target.products.map { |product| resource_factory.from(OpenStruct.new(resource_type: :product, resource_id: product.identifier)) }
  end

  private

    attr_reader :resource_factory
end
