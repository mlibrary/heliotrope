# frozen_string_literal: true

module Checkpoint::DB
  module Query
    # A query object based on agents and resources.
    #
    # This query finds grants for any supplied agents, for any supplied
    # resources. Its primary purpose is to find which credentials have been
    # granted to an agent on a given resource.
    #
    # It can take single items or arrays and converts them all to their tokens
    # for query purposes.
    class AR < CartesianSelect
      attr_reader :agents, :resources

      def initialize(agents, resources, scope: Grant)
        super(scope: scope)
        @agents = tokenize(agents)
        @resources = tokenize(resources)
      end

      def conditions
        super.merge(
          agent_token: agent_params.placeholders,
          resource_token: resource_params.placeholders
        )
      end

      def parameters
        super.merge((agent_params.values +
          resource_params.values).to_h)
      end

      protected

      def agent_params
        Params.new(agents, "at")
      end

      def resource_params
        Params.new(resources, "rt")
      end
    end
  end
end
