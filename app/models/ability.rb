class Ability
  include Hydra::Ability
  include CurationConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    return unless admin?
    can [:destroy], ActiveFedora::Base
    can :publish, Monograph
  end

  # TODO: For now, any signed in user is an admin
  def admin?
    # user_groups.include? 'admin'
    registered_user?
  end
end
