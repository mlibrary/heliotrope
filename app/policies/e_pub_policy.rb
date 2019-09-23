# frozen_string_literal: true

class EPubPolicy < ResourcePolicy
  def initialize(actor, target, share = false)
    target = target.parent
    super(actor, target)
    @share = share
  end

  def show? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    debug_log("show? #{actor.agent_type}:#{actor.agent_id}, #{target.resource_type}:#{target.resource_id}, share is #{share}")

    value = super
    debug_log("platform_admin? #{value}")
    return true if value

    value = Sighrax.published?(target)
    debug_log("published? #{value}")
    if value
      value = Sighrax.open_access?(target)
      debug_log("open_access? #{value}")
      return true if value

      value = Sighrax.restricted?(target)
      debug_log("restricted? #{value}")
      if value
        value = Sighrax.hyrax_can?(actor, :manage, target) && Incognito.allow_hyrax_can?(actor)
        debug_log("hyrax_can(:manage)? #{value}")
        return true if value

        debug_log("share #{share}")
        return true if share

        component = Greensub::Component.find_by(noid: target.noid)
        products = if Incognito.sudo_actor?(actor)
                     Incognito.sudo_actor_products(actor)
                   else
                     Greensub.actor_products(actor)
                   end
        debug_log("actor products: #{products.count}")
        products.each { |product| debug_log("actor product: #{product.identifier}") }
        debug_log("component products: #{component.products.count}")
        component.products.each { |product| debug_log("component product: #{product.identifier}") }
        value = (products & component.products).any?
        debug_log("actor_products_intersect_component_products_any? #{value}")
        value
      else
        true
      end
    else
      value = Sighrax.hyrax_can?(actor, :manage, target) && Incognito.allow_hyrax_can?(actor)
      debug_log("hyrax_can(:manage)? #{value}")
      return true if value

      value = Sighrax.hyrax_can?(actor, :read, target) && Incognito.allow_hyrax_can?(actor)
      debug_log("hyrax_can(:read)? #{value}")
      value
    end
  end

  protected

    attr_reader :share
end
