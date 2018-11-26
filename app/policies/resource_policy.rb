# frozen_string_literal: true

class ResourcePolicy < ApplicationPolicy
  def show?
    actor.is_a?(User) && actor.platform_admin?
  end

  def create?
    actor.is_a?(User) && actor.platform_admin?
  end

  def update?
    actor.is_a?(User) && actor.platform_admin?
  end

  def destroy?
    actor.is_a?(User) && actor.platform_admin?
  end

  def edit?
    update?
  end
end
