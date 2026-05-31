# frozen_string_literal: true
module ActiveTriples
  ##
  # Persistence strategy for projecting `RDFSource` to `RDF::Repositories`.
  class RepositoryStrategy
    include PersistenceStrategy

    # @!attribute [r] source
    #   the resource to persist with this strategy
    attr_reader :source

    ##
    # @param source [RDFSource, RDF::Enumerable] the `RDFSource` (or other
    #   `RDF::Enumerable` to persist with the strategy.
    def initialize(source)
      @source = source
    end

    ##
    # Deletes the resource from the repository.
    #
    def destroy
      super { source.clear }
    end

    ##
    # Clear out any old assertions in the repository about this node or statement
    # thus preparing to receive the updated assertions.
    def erase_old_resource
      if source.node?
        repository.statements.each do |statement|
          repository.send(:delete_statement, statement) if
            statement.subject == source
        end
      else
        repository.delete [source.to_term, nil, nil]
      end
    end

    ##
    # Persists the resource to the repository
    #
    # @return [true] returns true if the save did not error
    def persist!
      erase_old_resource
      repository << source
      @persisted = true
    end

    ##
    # Repopulates the graph from the repository.
    #
    # @return [Boolean]
    def reload
      source << repository.query([source, nil, nil])
      @persisted = true unless source.empty?
      true
    end

    ##
    # @return [RDF::Repository] The RDF::Repository that the resource will project
    #   itself on when persisting.
    def repository
      @repository ||= set_repository
    end

    private

      ##
      # Finds an appropriate repository from the calling resource's configuration.
      # If no repository is configured, builds an ephemeral in-memory
      # repository and 'persists' there.
      #
      # @todo find a way to move this logic out (PersistenceStrategyBuilder?).
      #   so the dependency on Repositories is externalized.
      def set_repository
        return RDF::Repository.new if source.class.repository.nil?
        repo = Repositories.repositories[source.class.repository]
        repo || raise(RepositoryNotFoundError, "The class #{source.class} expects a repository called #{source.class.repository}, but none was declared")
      end
  end
end
