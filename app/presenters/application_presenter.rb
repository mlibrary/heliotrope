class ApplicationPresenter
  attr_reader :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  delegate :platform_admin?, to: :@current_user

  def can_read?
    @current_user.platform_admin?
  end
end
