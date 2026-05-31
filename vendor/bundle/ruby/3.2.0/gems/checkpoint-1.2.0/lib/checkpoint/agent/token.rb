# frozen_string_literal: true

module Checkpoint
  class Agent
    # An Agent::Token is an identifier object for an Agent. It
    # includes a type and an identifier. A {Grant} can be created for a Token.
    # Concrete actors are resolved into a number of agents, and those agents'
    # tokens will be checked for matching grants.
    class Token
      attr_reader :type, :id

      # Create a new Agent Token representing an actor in an application.
      #
      # @param type [String] the application-determined type of this agent. This
      #   will commonly be 'user' or 'group', but may be anything that identifies
      #   a type of authentication attribute, such as 'account-type'. The type
      #   will be converted to a String if something else is supplied.
      # @param id [String] the application-resolvable identifier for this agent.
      #   This will commonly be username or group ID, but may be any value of an
      #   attribute of this type used to qualify an actor (user). The id
      #   will be converted to a String if something else is supplied.
      def initialize(type, id)
        @type = type.to_s
        @id = id.to_s
      end

      # @return [String] a URI for this agent, including its type and id
      def uri
        "agent://#{type}/#{id}"
      end

      # @return [Token] self; for convenience of taking an Agent or token
      def token
        self
      end

      # @return [String] a token string suitable for granting or matching grants for this agent
      def to_s
        "#{type}:#{id}"
      end

      # Compare with another Agent for equality. Consider them to represent
      # the same resource if `other` is an Agent, has the same type, and same id.
      def eql?(other)
        other.is_a?(Token) && type == other.type && id == other.id
      end

      # @return [Integer] hash code based on to_s
      def hash
        to_s.hash
      end

      alias_method :==, :eql?
      alias_method :inspect, :uri
      alias_method :agent_id, :id
      alias_method :agent_type, :type
    end
  end
end
