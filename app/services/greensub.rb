# frozen_string_literal: true

module Greensub
  class << self
    def actor_products(actor)
      products = actor.individual&.products || []
      actor.institutions.each do |institution|
        products += institution.products
      end
      products.uniq
    end

    def subscribed?(subscriber, product)
      Authority.permits?(subscriber, permission_read, product)
    end

    def subscribe(subscriber, product)
      Authority.grant!(subscriber, permission_read, product) unless Authority.permits?(subscriber, permission_read, product)
    end

    def unsubscribe(subscriber, product)
      Authority.revoke!(subscriber, permission_read, product) if Authority.permits?(subscriber, permission_read, product)
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

    def product_include?(product, entity)
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
