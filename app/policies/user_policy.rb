# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def initialize(current_user, user = nil)
    super(current_user, User, user)
  end
end
