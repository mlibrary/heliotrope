# frozen_string_literal: true

require "checkpoint/agent/resolver"
require "checkpoint/agent/token"

module Checkpoint
  # An Agent is an any person or entity that might be granted various
  # credentials, such as a user, group, or institution.
  #
  # The application objects that an agent represents may be of any type; this
  # is more of an interface or role than a base class. The important concept is
  # that credentials are granted to agents, and that agents may be representative
  # of multiple concrete actors, such as any person affiliated with a given
  # institution or any member of a given group.
  #
  # In an application, agents will typically be created by the
  # {Agent::Resolver} registered with an {Checkpoint::Authority}. This keeps
  # most of the application code decoupled from the Agent type, allowing the
  # binding to happen in an isolated component. It will also generally not be
  # required to subclass Agent, since it delegates to the concrete actor in
  # flexible, well-defined ways, detailed on the individual methods here.
  class Agent
    attr_accessor :actor

    # Create an Agent, wrapping a concrete actor.
    #
    # When retrieving the ID or type, we will delegate to the the actor at that
    # time. See the {#id} and {#type} methods for exact semantics.
    def initialize(actor)
      @actor = actor
    end

    # Convert this object to an Agent.
    #
    # For Checkpoint-supplied Agents, this is an identity operation,
    # but it allows consistent handling of the built-in types and
    # application-supplied types that will either implement this interface or
    # convert themselves to a built-in type. This removes the requirement to
    # extend Checkpoint types or bind to a specific conversion method.
    def to_agent
      self
    end

    # Get the wrapped actor's type.
    #
    # If the actor implements `#agent_type`, we will return that. Otherwise,
    # we use the actors's class name.
    #
    # @return [String] the name of the actor's type after calling `#to_s` on it.
    def type
      if actor.respond_to?(:agent_type)
        actor.agent_type
      else
        actor.class
      end.to_s
    end

    # Get the wrapped actor's ID.
    #
    # If the actor implements `#agent_id`, we will call it and return that
    # value. Otherwise, we call `#id`. If the the actor does not implement
    # either of these methods, we raise a {NoIdentifierError}.
    #
    # @return [String] the actor's ID after calling `#to_s` on it.
    def id
      if actor.respond_to?(:agent_id)
        actor.agent_id
      elsif actor.respond_to?(:id)
        actor.id
      else
        raise NoIdentifierError, "No usable identifier on actor of type: #{actor.class}"
      end.to_s
    end

    def token
      @token ||= Token.new(type, id)
    end

    # Check whether two Agents refer to the same concrete actor.
    # @param other [Agent] Another Agent to compare with
    # @return [Boolean] true when the other Agent's actor is the same as
    #   determined by comparing them with `#eql?`.
    def eql?(other)
      other.is_a?(Agent) && actor.eql?(other.actor)
    end

    # Check whether two Agents refer to the same concrete actor by type and id.
    # @param other [Agent] Another Agent to compare with
    # @return [Boolean] true when the other Agent's type and id are equal.
    def ==(other)
      other.is_a?(Agent) && type == other.type && id == other.id
    end
  end
end
