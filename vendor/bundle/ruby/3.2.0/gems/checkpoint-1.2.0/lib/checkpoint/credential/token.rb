# frozen_string_literal: true

module Checkpoint
  class Credential
    # A Credential::Token is an identifier object for a Credential. It includes
    # a type and an identifier. A {Grant} can be created for a Token. Concrete
    # actions are resolved into a number of credentials, and those credentials'
    # tokens will be checked for matching grants.
    class Token
      attr_reader :type, :id

      # Create a new Credential representing a permission or instrument that
      # represents multiple permissions.
      #
      # @param type [String] the application-determined type of this credential.
      #   For example, this might be 'permission' or 'role'.
      #
      # @param id [String] the application-resolvable identifier for this
      #   credential. For example, this might be an action to be taken or the ID
      #   of a role.
      def initialize(type, id)
        @type = type.to_s
        @id = id.to_s
      end

      # @return [String] a URI for this credential, including its type and id
      def uri
        "credential://#{type}/#{id}"
      end

      # @return [Token] self; for convenience of taking a Credential or token
      def token
        self
      end

      # @return [String] a token suitable for granting or matching this credential
      def to_s
        "#{type}:#{id}"
      end

      # Compare with another Credential for equality. Consider them to represent
      # the same credential if `other` is a credential, has the same type, and same id.
      def eql?(other)
        other.is_a?(Token) && type == other.type && id == other.id
      end

      # @return [Integer] hash code based on to_s
      def hash
        to_s.hash
      end

      alias_method :==, :eql?
      alias_method :inspect, :uri
      alias_method :credential_type, :type
      alias_method :credential_id, :id
    end
  end
end
