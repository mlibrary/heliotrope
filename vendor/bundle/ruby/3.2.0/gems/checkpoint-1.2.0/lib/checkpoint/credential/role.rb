# frozen_string_literal: true

module Checkpoint
  class Credential
    # A Role is simple extension to the base Credential, specifying its type
    # as a role and providing a conceptual object to be instantiated or passed.
    #
    # The most common use from outside Checkpoint will be by way of
    # {Checkpoint::Query::RoleGranted}, which will ask whether a given named
    # role is granted for a user. However, Role could be extended or modified
    # to implement aliasing or hierarchy, for example.
    #
    # More likely, though, is implementing a custom
    # {Checkpoint::Credential::Resolver}. Subclassing or monkey-patching Role
    # should only be necessary if the application needs to extend the actual
    # behavior of the Role objects, rather than just which ones are resolved.
    class Role < Credential
      TYPE = "role"

      def type
        TYPE
      end
    end
  end
end
