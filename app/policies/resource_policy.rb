# frozen_string_literal: true

class ResourcePolicy < ApplicationPolicy
  def show?
    actor_platform_admin?
  end

  def create?
    actor_platform_admin?
  end

  def update?
    actor_platform_admin?
  end

  def destroy?
    actor_platform_admin?
  end

  def edit?
    update?
  end

  private

    def actor_platform_admin?
      @actor_platform_admin ||= Sighrax.platform_admin?(actor)
    end
end
