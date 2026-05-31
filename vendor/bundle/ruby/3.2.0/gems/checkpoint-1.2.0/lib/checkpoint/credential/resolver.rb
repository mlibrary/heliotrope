# frozen_string_literal: true

module Checkpoint
  class Credential
    # A Credential Resolver is the bridge between application action names
    # and {Credential}s that would permit those actions.
    #
    # Checkpoint makes no particular demand on the credential model for an
    # application, but offers two useful default implementations supporting
    # permissions and roles. There are no default rules in Checkpoint as to which
    # permissions or roles exist and, therefore, it has no default mapping of
    # roles to permissions.
    #
    # This default resolver is useful for applications that only deal with
    # permissions or model credentials in an object-oriented way (explained
    # below). The {RoleMapResolver} supports a basic mapping pattern between
    # named roles and permissions those roles would grant.
    #
    # More sophisticated mappings, such as those reading a configuration file
    # or with dynamic roles and permissions defined in a database, can be
    # implemented in a custom resolver.
    #
    # Using this default resolver, it is possible to implement your own
    # {Credential} types to model an application's credentials in an
    # object-oriented way. If the resolver receives a {Credential} (rather than
    # a string or symbol), it will call `#granted_by` on it to expand it. The
    # Credential should be sure to include itself in the array it returns
    # unless it is virtual and should never be considered as granted directly.
    #
    # An example of this type of modeling could be implementing named action
    # classes that have information like labels and descriptions for display
    # purposes in a permission management interface or messages when a user
    # does not have sufficient permission to take that action. There might also
    # be some inheritance such that granting something like "manage" would be a
    # shorthand for all CRUD operations on a Resource type.
    #
    # Another example of a custom Credential type could be a license that would
    # be an application object in its own right, carrying information such as
    # the licensor and expiration date. By implementing the Credential
    # interface, a license could be granted directly with the Checkpoint
    # {Authority} and enforced at the policies.
    #
    # @see {RoleMapResolver}
    class Resolver
      # Expand an action into all {Credential}s that would permit it.
      #
      # Expansion first converts the action to a Credential, and then calls
      # `#granted_by` on it.
      #
      # Note that the parameter name is `action`, though it can accept a
      # Credential. This is to promote the most common and recommended model:
      # authorizing based on named application actions. However, the
      # polymorphic and hierarchical nature of credentials means that there can
      # be cases where expanding something like a {Role} is intentional. As an
      # example, an administrative interface for managing roles granted to
      # users might need to expand the roles to show inheritance, rather than
      # checking whether a given user would be permitted to take some action.
      #
      # @param action [String|Symbol|Credential] the action name or Credential
      #   to expand
      # @return [Array<Credential>] the set of Credentials, any of which would
      #   allow the action
      def expand(action)
        convert(action).granted_by
      end

      # Convert an action to a Credential.
      #
      # This conversion is basic, assuming that actions should convert directly
      # to permissions. For example, if `:read` or `'read'` is passed, a
      # {Credential::Permission} with id `'read'` is returned. If the action
      # implements `#to_credential`, that will be called and returned; the
      # object must either extend {Credential} or implement its public methods.
      #
      # @param action [String|Symbol|Credential] the action name or Credential
      #   to convert
      # @return Credential a Credential object that would specifically allow
      #   the action supplied
      def convert(action)
        if action.respond_to?(:to_credential)
          action.to_credential
        else
          Permission.new(action)
        end
      end
    end
  end
end
