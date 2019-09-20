# frozen_string_literal: true

require_dependency 'greensub/component'
require_dependency 'greensub/components_product'
require_dependency 'greensub/individual'
require_dependency 'greensub/institution'
require_dependency 'greensub/product'

module Greensub
  class << self
    def actor_products(actor)
      products = actor.individual&.products || []
      actor.institutions.each do |institution|
        products += institution.products
      end
      products.uniq
    end

    def subscribed?(subscriber:, target:)
      Authority.permits?(subscriber, permission_read, target)
    end

    def subscribe(subscriber:, target:)
      return if subscribed?(subscriber: subscriber, target: target)
      Authority.grant!(subscriber, permission_read, target) unless Authority.permits?(subscriber, permission_read, target)
    end

    def unsubscribe(subscriber:, target:)
      Authority.revoke!(subscriber, permission_read, target) if Authority.permits?(subscriber, permission_read, target)
    end

    def subscriber_products(subscriber)
      resources = Authority.which(subscriber, permission_read)
      products = resources.map { |resource| Authority.resource(resource.type, resource.id) if resource.type == Product.new.resource_type.to_s }
      products.compact
    end

    def product_subscribers(product)
      agents = Authority.who(permission_read, product)
      subscribers = agents.map { |agent| Authority.agent(agent.type, agent.id) if agent.type == Individual.new.agent_type.to_s || agent.type == Institution.new.agent_type.to_s }
      subscribers.compact
    end

    def product_include?(product:, entity:)
      return false unless product.present? && entity.present?
      noids = product.components.map(&:noid)
      noids.include?(entity.noid)
    end

    private
      def permission_read
        @permission_read ||= Checkpoint::Credential::Permission.new(:read)
      end
  end
end
