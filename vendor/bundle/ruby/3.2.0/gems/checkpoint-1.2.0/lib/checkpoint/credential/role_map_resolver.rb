# frozen_string_literal: true

class Checkpoint::Credential
  # Credential Resolver that supports a basic role map model.
  #
  # The role map should be a hash containing all of the roles and each key
  # should be an array of the permissions that role would grant. For example:
  #
  # ```
  # {
  #   admin: [:read, :create, :edit, :delete],
  #   guest: [:read]
  # }
  # ```
  #
  # Note that this example is not a recommendation of how to model an
  # application's permissions; it is only to show the expected format of the
  # hash and that there is no inheritance of permissions between roles (:read
  # is included in both roles). Any more sophisticated rules should be
  # implemented in a custom Resolver, or custom Credential types.
  #
  # Actions convert to Permissions according to the base {Resolver} and expand
  # according to the map.
  class RoleMapResolver < Resolver
    attr_reader :role_map, :permission_map

    def initialize(role_map)
      @role_map = role_map
      @permission_map = invert_role_map
    end

    # Expand an action name into the matching permission and any roles that
    # would grant it.
    #
    # @return [Array<Credential>]
    def expand(action)
      permissions_for(action) + roles_granting(action)
    end

    private

    def permissions_for(action)
      [Permission.new(action)]
    end

    def roles_granting(action)
      if permission_map.key?(action)
        permission_map[action].map { |role| Role.new(role) }
      else
        []
      end
    end

    def invert_role_map
      {}.tap do |hash|
        role_map.each do |role, permissions|
          permissions.each do |permission|
            hash[permission] ||= []
            hash[permission] << role
          end
        end
      end
    end
  end
end
