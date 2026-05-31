# frozen_string_literal: true

module Checkpoint::DB
  module Query
    # A query object based on credentials and resources.
    #
    # This query finds grants for any supplied credentials, for any supplied
    # resources. Its primary purpose is to find which agents have been granted
    # a given credential on a resource.
    #
    # It can take single items or arrays and converts them all to their tokens
    # for query purposes.
    class CR < CartesianSelect
      attr_reader :credentials, :resources

      def initialize(credentials, resources, scope: Grant)
        super(scope: scope)
        @credentials = tokenize(credentials)
        @resources = tokenize(resources)
      end

      def conditions
        super.merge(
          credential_token: credential_params.placeholders,
          resource_token: resource_params.placeholders
        )
      end

      def parameters
        super.merge((credential_params.values +
          resource_params.values).to_h)
      end

      protected

      def credential_params
        Params.new(credentials, "ct")
      end

      def resource_params
        Params.new(resources, "rt")
      end
    end
  end
end
