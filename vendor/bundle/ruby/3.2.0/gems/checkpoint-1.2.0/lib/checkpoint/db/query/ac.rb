# frozen_string_literal: true

module Checkpoint::DB
  module Query
    # A query object based on agents and credentials.
    #
    # This query finds grants for any supplied agents, for any supplied
    # credentials. Its primary purpose is to find which resources for which an
    # agent has been granted a given credential.
    #
    # It can take single items or arrays and converts them all to their tokens
    # for query purposes.
    class AC < CartesianSelect
      attr_reader :agents, :credentials

      def initialize(agents, credentials, scope: Grant)
        super(scope: scope)
        @agents = tokenize(agents)
        @credentials = tokenize(credentials)
      end

      def conditions
        super.merge(
          agent_token: agent_params.placeholders,
          credential_token: credential_params.placeholders
        )
      end

      def parameters
        super.merge((agent_params.values +
          credential_params.values).to_h)
      end

      protected

      def agent_params
        Params.new(agents, "at")
      end

      def credential_params
        Params.new(credentials, "ct")
      end
    end
  end
end
