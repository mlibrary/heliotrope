class Ability
  include Hydra::Ability
  include CurationConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    can [:index, :read], Press

    # press admin
    can :manage, Role, resource_id: @user.admin_roles.pluck(:resource_id), resource_type: 'Press'
    return unless platform_admin?
    can [:destroy], ActiveFedora::Base
    can :publish, Monograph
  end

  def platform_admin?
    @user.platform_admin?
  end
  alias admin? platform_admin?
end
