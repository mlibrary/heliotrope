# frozen_string_literal: true

require "checkpoint/credential/resolver"
require "checkpoint/credential/role_map_resolver"
require "checkpoint/credential/role"
require "checkpoint/credential/permission"
require "checkpoint/credential/token"

module Checkpoint
  # A Credential is the permission to take a particular action, or any
  # instrument that can represent multiple permissions, such as a role or
  # license.
  #
  # Credentials are abstract; that is, they are not attached to a particular
  # actor or resource to be acted upon. A credential can be granted to an
  # {Agent}, optionally applying to a particular resource, by way of a Grant.
  # In other words, a credential can be likened to a class, while a grant can
  # be likened to an instance of that class, bound to a given agent and
  # possibly bound to a {Resource}.
  class Credential
    attr_reader :type, :id
    alias_method :name, :id

    # Create a new generic Credential. This should generally not be called,
    # preferring to use a factory or instantiate a {Permission}, {Role}, or
    # custom Credential class.
    #
    # This class assigns the type 'credential', while most often, applications
    # will want a {Permission}.
    #
    # The term `name` is more intuitive for credentials than `id`, as is used
    # with the {Agent} and {Resource} types. This is because most applications
    # will use primitive strings or symbols as the programmatic objects for
    # credentials, where as `id` is often associated with a database-assigned
    # identifier that should not appear in the source code. The parameter is
    # called `name` here to reflect that intuitive concept, but it is really
    # an alias for the `id` property of this Credential.
    #
    # @param name [String|Symbol] the name of this credential
    def initialize(name)
      @id = name.to_s
      @type = "credential"
    end

    # Return the list of Credentials that would grant this one.
    #
    # This is an extension mechanism for application authors needing to
    # implement hierarchical or virtual credentials and wanting to do so in
    # an object-oriented way. The default implementation is to simply return
    # the credential itself in an array but, for example, a custom
    # permission type could provide for aliasing by including itself and
    # another instance for the synonym. Another example is modeling permissions
    # granted by particular roles; this might be static, as defined in the
    # source files, or dynamic, as impacted by configuration or runtime data.
    #
    # As an alternative, these rules could be implemented by using the rather
    # straightforward {RoleMapResolver} or a custom {Credential::Resolver}.
    #
    # @return [Array<Credential>] the expanded list of credentials that would
    #   grant this one
    def granted_by
      [self]
    end

    # Convert this object to a Credential.
    #
    # For Checkpoint-supplied Credential types, this is an identity operation,
    # but it allows consistent handling of the built-in types and
    # application-supplied types that will either implement this interface or
    # convert themselves to a built-in type. This removes the requirement to
    # extend Checkpoint types and, in combination with `#granted_by`, allows
    # design of an object-oriented permission model that can interoperate
    # seamlessly with the Checkpoint constructs.
    #
    # @return [Credential] this credential
    def to_credential
      self
    end

    # @return [Token] a token for this credential
    def token
      @token ||= Token.new(type, id)
    end

    # Compare two Credentials.
    # @param other [Credential] the Credential to compare
    # @return [Boolean] true if `other` is a Credential and its type and id
    #   are both eql? to {#type} and {#id}
    def eql?(other)
      type.eql?(other.type) && name.eql?(other.id)
    end

    alias_method :==, :eql?
  end
end
