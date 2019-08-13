# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  # Define any customized permissions here.
  def custom_permissions
    can [:read], ApplicationPresenter, &:can_read?
    can [:read], UsersPresenter, &:can_read?
    can [:read], UserPresenter, &:can_read?
    can [:read], RolesPresenter, &:can_read?
    can [:read], RolePresenter, &:can_read?

    can %i[index read], Press

    # press admin
    grant_press_admin_abilities

    grant_platform_admin_abilities
  end

  def grant_press_admin_abilities
    can :manage, Role, resource_id: @user.admin_roles.pluck(:resource_id), resource_type: 'Press'

    can :manage, FeaturedRepresentative

    can %i[create update], Monograph do |m|
      @user.admin_presses.pluck(:subdomain).include?(m.press) && !only_scores
    end

    can %i[create update], Score do
      @user.admin_presses.pluck(:subdomain).include?(Services.score_press)
    end

    can %i[create update], ::Hyrax::FileSet do |f|
      @user.admin_presses.map(&:subdomain).include?(f.parent.press) unless f.parent.nil?
    end

    can :update, Press do |p|
      admin_for?(p)
    end

    # For the different view presenters
    can :update, Hyrax::MonographPresenter do |p|
      @user.admin_presses.map(&:subdomain).include?(p.subdomain) && !only_scores
    end

    can :update, Hyrax::ScorePresenter do
      @user.admin_presses.pluck(:subdomain).include?(Services.score_press)
    end

    can :update, Hyrax::FileSetPresenter do |p|
      @user.admin_presses.map(&:subdomain).include?(p.parent.subdomain)
    end

    can :read, :admin_dashboard do
      @user.admin_presses.present?
    end
  end

  def grant_platform_admin_abilities
    return unless platform_admin?
    can [:destroy], ActiveFedora::Base
    can :publish, Monograph
    can :manage, Role
    can :manage, Press
    can :manage, FeaturedRepresentative
    can :manage, User
  end

  def platform_admin?
    @user.platform_admin?
  end
  alias admin? platform_admin?

  def admin_for?(press)
    @user.admin_presses.include?(press)
  end

  def press_admin?
    @user.admin_presses.count.positive?
  end

  def only_scores
    @user.admin_presses.count == 1 && @user.admin_presses.pluck(:subdomain).first == Services.score_press
  end
end
