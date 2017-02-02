class RolePresenter
  attr_reader :role, :user, :current_user

  def initialize(role, user, current_user)
    @role = role
    @user = user
    @current_user = current_user
  end

  delegate :id, to: :@role

  def name
    suffix = press? ? " (#{press.subdomain})" : ''
    @role.role + suffix
  end

  def press?
    !@role.resource_id.nil?
  end

  def press
    press? ? Press.find(@role.resource_id) : nil
  end

  def can_read?
    (@user == @current_user) || @current_user.platform_admin? || (press? ? @current_user.admin_presses.include?(press) : false)
  end
end
