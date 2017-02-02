class RolesPresenter
  attr_reader :user, :current_user

  def initialize(user, current_user)
    @user = user
    @current_user = current_user
  end

  def all
    (@user.roles.map { |role| RolePresenter.new(role, @user, @current_user) }).sort! { |x, y| x.name <=> y.name }
  end

  def can_read?
    true
  end
end
