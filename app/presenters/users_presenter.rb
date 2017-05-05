# frozen_string_literal: true

class UsersPresenter
  attr_reader :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def all
    (User.all.map { |user| UserPresenter.new(user, @current_user) }).sort! { |x, y| x.email <=> y.email }
  end

  def can_read?
    @current_user.roles.where(role: 'admin').any?
  end
end
