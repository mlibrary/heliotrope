# frozen_string_literal: true
module Valkyrie::Indexers
  # Provides an optional interface consistent with Hydra::AccessControls
  #   This allows for storing access control information into an index
  #
  # @note This is used primarily with Solr
  #
  # @example Use in Solr Adapter with a CompositeIndexer
  #
  #   # insert into config/initializers/valkyrie.rb
  #   Valkyrie::MetadataAdapter.register(
  #       Valkyrie::Persistence::Solr::MetadataAdapter.new(
  #           connection: Blacklight.default_index.connection,
  #           resource_indexer: Valkyrie::Persistence::Solr::CompositeIndexer.new(
  #               Valkyrie::Indexers::AccessControlsIndexer,
  #               Collection::TypeIndexer
  #           )
  #       ),
  #       :index_solr
  #   )
  #
  # @see https://github.com/pulibrary/figgy/blob/684a4fb71cad1c9592d8272416f36e2a4f4ae3c4/config/initializers/valkyrie.rb#L82
  # @see lib/valkyrie/resource/access_controls.rb
  class AccessControlsIndexer
    attr_reader :resource, :config
    def initialize(resource:, config: default_config)
      @resource = resource
      @config = config
    end

    def to_solr
      return {} unless resource.respond_to?(:read_users)
      {
        config.fetch(:read_groups) => resource.read_groups,
        config.fetch(:read_users) => resource.read_users,
        config.fetch(:edit_users) => resource.edit_users,
        config.fetch(:edit_groups) => resource.edit_groups
      }
    end

    private

    # rubocop:disable Metrics/MethodLength
    def default_config
      if defined?(Hydra) && Hydra.respond_to?(:config)
        {
          read_groups: Hydra.config[:permissions][:read].group,
          read_users: Hydra.config[:permissions][:read].individual,
          edit_groups: Hydra.config[:permissions][:edit].group,
          edit_users: Hydra.config[:permissions][:edit].individual
        }
      else
        {
          read_groups: 'read_access_group_ssim',
          read_users: 'read_access_person_ssim',
          edit_groups: 'edit_access_group_ssim',
          edit_users: 'edit_access_person_ssim'
        }
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
