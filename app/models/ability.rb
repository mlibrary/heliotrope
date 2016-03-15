class Ability
  include Hydra::Ability
  include CurationConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    if admin?
      can [:destroy], ActiveFedora::Base
    end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end
  end

  # TODO: For now, any signed in user is an admin
  def admin?
    # user_groups.include? 'admin'
    registered_user?
  end
end
