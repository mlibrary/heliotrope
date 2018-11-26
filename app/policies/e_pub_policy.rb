# frozen_string_literal: true

class EPubPolicy < ResourcePolicy
  def initialize(actor, target, share = false)
    super(actor, target)
    @share = share
  end

  def show?
    return true if super
    return true if Sighrax.hyrax_can?(actor, :read, target)
    return false unless Sighrax.published?(target)
    return true unless Sighrax.restricted?(target)
    return true if @share
    action_permitted?(:read)
  end
end
