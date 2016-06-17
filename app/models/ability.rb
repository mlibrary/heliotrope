class Ability
  include Hydra::Ability
  include CurationConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    can [:index, :read], Press
    can [:read], SubBrand

    # press admin
    can :manage, Role, resource_id: @user.admin_roles.pluck(:resource_id), resource_type: 'Press'

    # monograph.press is a String (the subdomain of a Press)
    can :create, Monograph do |m|
      @user.admin_presses.map(&:subdomain).include?(m.press)
    end

    can :manage, SubBrand do |sb|
      admin_for?(sb.press)
    end

    can :update, Press do |p|
      admin_for?(p)
    end

    grant_platform_admin_abilities
  end

  def grant_platform_admin_abilities
    return unless platform_admin?
    can [:destroy], ActiveFedora::Base
    can :publish, Monograph
    can :manage, Role
  end

  def platform_admin?
    @user.platform_admin?
  end
  alias admin? platform_admin?

  def admin_for?(press)
    @user.admin_presses.include?(press)
  end
end
