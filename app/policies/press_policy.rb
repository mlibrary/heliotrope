# frozen_string_literal: true

class PressPolicy < ApplicationPolicy
  alias_attribute :press, :target

  def interval_download?
    return true if actor_platform_admin?
    /^heb$/.match?(press.subdomain)
  end

  private

    def actor_platform_admin?
      @actor_platform_admin ||= Sighrax.platform_admin?(actor)
    end
end
