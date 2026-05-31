# frozen_string_literal: true
module Valkyrie
  class Resource
    # Provides an optional interface consistent with Hydra::AccessControls
    #
    # @example
    #     class CustomResource < Valkyrie::Resource
    #       include Valkyrie::Resource::AccessControls
    #       attribute :title
    #       attribute :member_ids
    #       attribute :nested_resource
    #     end
    #
    # @see https://github.com/samvera/hydra-head/tree/main/hydra-access-controls
    # @see lib/valkyrie/indexers/access_controls_indexer/rb
    module AccessControls
      def self.included(klass)
        klass.attribute :read_groups, Valkyrie::Types::Set
        klass.attribute :read_users, Valkyrie::Types::Set
        klass.attribute :edit_users, Valkyrie::Types::Set
        klass.attribute :edit_groups, Valkyrie::Types::Set
      end
    end
  end
end
