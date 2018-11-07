# frozen_string_literal: true

require 'checkpoint/resource'

class TargetResourceResolver < Checkpoint::Resource::Resolver
  def expand(entity)
    resources = super(entity) + components(entity) + products(entity)
    resources
  end

  def convert(entity)
    resource = super(entity)
    resource
  end

  private

    def components(entity)
      return [] if entity.component.blank?
      [convert(entity.component)]
    end

    def products(entity)
      entity.products.map { |product| convert(product) }
    end
end
