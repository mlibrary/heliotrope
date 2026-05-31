# frozen_string_literal: true

module Checkpoint
  module DB
    # Helper for querying by cross-products across sets of parameters,
    # especially for grants.
    #
    # This class is called CartesianSelect because the logical search space is
    # the Cartesian product, for example, of agents X credentials X resources.
    # All grants in that space would be selected.
    #
    # This is a base class to support convenient variations for searching in
    # different scenarios. It is unlikely to be very useful in its own right,
    # but provides structure for specific subclasses. For example, {Query::ACR}
    # searches for grants when agents, credentials, and resources are all
    # known, as when checking authorization. When seeking to list agents that
    # could take a given action on a resource, {Query::CR} would be useful.
    #
    # Subclasses should extends the conditions and parameters methods to supply
    # the placeholders and matching values. The {Params} class is helpful for
    # that purpose.
    #
    # The queries are ultimately implemented with an IN clause for each key in
    # the conditions with binding expressions in the way Sequel expects them.
    class CartesianSelect
      attr_reader :scope

      def initialize(scope: Grant)
        @scope = scope
      end

      def query
        scope.where(conditions)
      end

      def all
        exec(:select)
      end

      def first
        exec(:first)
      end

      def delete
        exec(:delete)
      end

      def conditions
        {
          zone_id: :$zone_id
        }
      end

      def parameters
        {
          zone_id: Grant.default_zone
        }
      end

      private

      def exec(mode)
        query.call(mode, parameters)
      end

      def tokenize(collection)
        [collection].flatten.map(&:token)
      end
    end
  end
end
