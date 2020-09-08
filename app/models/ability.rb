# frozen_string_literal: true

class Ability
  include Hydra::Ability
  include Hyrax::Ability

  # CanCanCan default aliases
  #
  # alias_action :index, :show, :to => :read
  # alias_action :new, :to => :create
  # alias_action :edit, :to => :update

  # Define any customized permissions here.
  def custom_permissions # rubocop:disable Metrics/CyclomaticComplexity
    can :read, ApplicationPresenter, &:can_read?
    can :read, UsersPresenter, &:can_read?
    can :read, UserPresenter, &:can_read?
    can :read, RolesPresenter, &:can_read?
    can :read, RolePresenter, &:can_read?

    can :read, Press

    grant_press_editor_abilities if platform_admin? || press_admin? || press_editor?
    grant_press_admin_abilities if platform_admin? || press_admin?
    grant_platform_admin_abilities if platform_admin?
  end

  def grant_press_editor_abilities
    can :manage, Monograph do |m|
      @user.editor_presses.pluck(:subdomain).include?(m.press) && !only_scores
    end

    can :manage, Score do
      @user.editor_presses.pluck(:subdomain).include?(Services.score_press)
    end

    can :manage, FileSet do |f|
      @user.editor_presses.map(&:subdomain).include?(f.parent.press) unless f.parent.nil?
    end

    # For the different view presenters
    can :update, Hyrax::MonographPresenter do |p|
      @user.editor_presses.map(&:subdomain).include?(p.subdomain) && !only_scores
    end

    can :update, Hyrax::ScorePresenter do
      @user.editor_presses.pluck(:subdomain).include?(Services.score_press)
    end

    can :update, Hyrax::FileSetPresenter do |p|
      @user.editor_presses.map(&:subdomain).include?(p.parent.subdomain)
    end
  end

  def grant_press_admin_abilities
    can :manage, Role, resource_id: @user.admin_roles.pluck(:resource_id), resource_type: 'Press'

    can :manage, FeaturedRepresentative

    can :manage, Monograph do |m|
      @user.admin_presses.pluck(:subdomain).include?(m.press) && !only_scores
    end

    can :manage, Score do
      @user.admin_presses.pluck(:subdomain).include?(Services.score_press)
    end

    can :manage, FileSet do |f|
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
    can :destroy, ActiveFedora::Base
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

  def press_admin?
    @user.admin_presses.count.positive?
  end

  def admin_for?(press)
    @user.admin_presses.include?(press)
  end

  def press_editor?
    @user.editor_presses.count.positive?
  end

  def editor_for?(press)
    @user.editor_presses.include?(press)
  end

  def only_scores
    @user.admin_presses.count == 1 && @user.admin_presses.pluck(:subdomain).first == Services.score_press
  end
end
