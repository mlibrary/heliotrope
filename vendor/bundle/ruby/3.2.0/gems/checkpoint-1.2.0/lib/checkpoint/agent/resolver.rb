# frozen_string_literal: true

module Checkpoint
  class Agent
    # An Agent Resolver is the bridge between a concrete user (or other
    # account/actor) and {Agent}s that the user represents.
    #
    # There are two basic operations:
    #
    # - Conversion maps an actor to a single Agent
    # - Expansion maps an actor to all of the Agents it represents
    #
    # These allow credentials to be granted, matched, or revoked with the
    # appropriate semantics, depending on the operation. In general, a Grant
    # is given to or revoked from a single Agent, while matching is applied
    # to all Agents the actor represents.
    #
    # This implementation does not implement any expansion semantics other
    # than to convert the actor into an Agent and return it as a list.
    #
    # To extend the set of {Agent}s resolved, implement a subclass
    # that returns an array of agents from #expand. This customized
    # implementation would typically be injected to an application-wide
    # {Checkpoint::Authority}, rather than being used directly.
    #
    # For example, a custom resolver might add a group agent for each group that
    # the user is a member of, or IP address-based geographical regions or
    # organizational affiliations.
    class Resolver
      # Expand an actor to a list of Agents it represents.
      #
      # This implementation simply converts the actor and wraps the resulting
      # Agent in an array.
      #
      # If extending or overriding, you will likely want to call super or
      # {#convert} on the concrete actor to make sure that the most specific
      # Agent is included. It is acceptable to return subclasses of Agent,
      # though that is generally unnecessary because of its design of
      # delegating to actor methods.
      #
      # @return [Agent] an array of agents for this actor
      def expand(actor)
        [convert(actor)]
      end

      # Default conversion from an actor to an {Agent}.
      #
      # If the actor implements #to_agent, we will delegate to it. Otherwise,
      # we will instantiate an {Agent} with the supplied actor.
      #
      # Override this method to use a different or conditional Agent type.
      #
      # @return [Agent] the actor converted to an agent
      def convert(actor)
        if actor.respond_to?(:to_agent)
          actor.to_agent
        else
          Agent.new(actor)
        end
      end
    end
  end
end
