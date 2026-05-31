# frozen_string_literal: true

module Checkpoint::DB
  module Query
    # A query object based on agents, credentials, and resources.
    #
    # This query mirrors the essence of the Checkpoint semantics; that is, it
    # finds grants for any supplied agents, for any supplied credentials, for
    # any supplied resources.
    #
    # It can take single items or arrays and converts them all to their tokens
    # for query purposes.
    class ACR < CartesianSelect
      attr_reader :agents, :credentials, :resources

      def initialize(agents, credentials, resources, scope: Grant)
        super(scope: scope)
        @agents = tokenize(agents)
        @credentials = tokenize(credentials)
        @resources = tokenize(resources)
      end

      def conditions
        super.merge(
          agent_token: agent_params.placeholders,
          credential_token: credential_params.placeholders,
          resource_token: resource_params.placeholders
        )
      end

      def parameters
        super.merge((agent_params.values +
          credential_params.values +
          resource_params.values).to_h)
      end

      protected

      def agent_params
        Params.new(agents, "at")
      end

      def credential_params
        Params.new(credentials, "ct")
      end

      def resource_params
        Params.new(resources, "rt")
      end
    end
  end
end
