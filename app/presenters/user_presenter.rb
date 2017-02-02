class UserPresenter
  attr_reader :user, :current_user

  def initialize(user, current_user)
    @user = user
    @current_user = current_user
  end

  delegate :id, :email, to: :@user

  def roles?
    @user.roles.any?
  end

  def roles
    RolesPresenter.new(@user, @current_user)
  end

  def can_read?
    (@user == @current_user) || @current_user.platform_admin? || (@user.presses & @current_user.admin_presses).any?
  end
end
