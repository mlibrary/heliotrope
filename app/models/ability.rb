class Ability
  include Hydra::Ability
  include CurationConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    return unless platform_admin?
    can [:destroy], ActiveFedora::Base
    can :publish, Monograph
  end

  def platform_admin?
    @user.platform_admin?
  end
  alias admin? platform_admin?
end
