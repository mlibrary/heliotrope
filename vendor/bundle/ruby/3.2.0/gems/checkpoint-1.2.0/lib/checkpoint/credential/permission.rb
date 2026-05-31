# frozen_string_literal: true

module Checkpoint
  class Credential
    # A Permission is simple extension to the base Credential, specifying its
    # type as a permission and providing a conceptual object to be instantiated
    # or passed.
    #
    # The most common use from outside Checkpoint will be by way of
    # {Checkpoint::Query::ActionPermitted}, which will ask whether a given named
    # action is permitted for a user. However, Permission could be extended or
    # modified to implement aliasing or hierarchy, for example.
    #
    # More likely, though, is advising the resolution of Permissions with a
    # role map and {Checkpoint::Credential::RoleMapResolver} or implementing a
    # custom {Checkpoint::Credential::Resolver}. Subclassing or monkey-patching
    # Permission should only be necessary if the application needs to extend
    # the actual behavior of the Permission objects, rather than just which
    # ones are resolved.
    class Permission < Credential
      TYPE = "permission"

      def type
        TYPE
      end
    end
  end
end
