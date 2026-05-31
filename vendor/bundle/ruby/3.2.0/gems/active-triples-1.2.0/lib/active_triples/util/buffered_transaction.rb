require 'active_triples/util/extended_bounded_description'

module ActiveTriples
  ##
  # A buffered trasaction for use with `ActiveTriples::ParentStrategy`.
  #
  # If an `ActiveTriples::RDFSource` instance is passed as the underlying 
  # repository, this transaction will try to find an existing 
  # `BufferedTransaction` to use as the basis for a snapshot. When the 
  # transaction is executed, the inserts and deletes are replayed against the
  # `RDFSource`.
  #
  # If a `RDF::Transaction::TransactionError` is raised on commit, this 
  # transaction optimistically attempts to replay the changes.
  #
  # Reads are projected onto a specialized "Extended Bounded Description" 
  # subgraph. 
  #
  # @see ActiveTriples::Util::ExtendedBoundedDescription
  class BufferedTransaction < 
        RDF::Repository::Implementation::SerializedTransaction
    # @!attribute snapshot [r]
    #   @return RDF::Dataset
    # @!attribute subject [r]
    #   @return RDF::Term
    # @!attribute ancestors [r]
    #   @return Array<RDF::Term>
    attr_reader :snapshot, :subject, :ancestors
    
    def initialize(repository,
                   ancestors:  [],
                   subject:    nil, 
                   graph_name: nil, 
                   mutable:    false, 
                   **options,
                   &block)
      @subject   = subject
      @ancestors = ancestors

      if repository.is_a?(RDFSource)
        if repository.persistence_strategy.graph.is_a?(BufferedTransaction)
          super
          @snapshot = repository.persistence_strategy.graph.snapshot
          return
        else
          repository = repository.persistence_strategy.graph.data
        end
      end

      return super
    end

    ##
    # Provides :repeatable_read isolation (???)
    #
    # @see RDF::Transaction#isolation_level
    def isolation_level
      :repeatable_read
    end

    ##
    # @return [BufferedTransaction] self
    def data
      self
    end

    ##
    # @see RDF::Mutable#supports
    def supports?(feature)
      return true if feature.to_sym == :snapshots
    end

    ##
    # Adds statement to the `inserts` collection of the buffered changeset and
    # updates the snapshot.
    #
    # @see RDF::Mutable#insert_statement
    def insert_statement(statement)
      @changes.insert(statement)
      @changes.deletes.delete(statement)
      super
    end

    ##
    # Adds statement to the `deletes` collection of the buffered changeset and
    # updates the snapshot.
    #
    # @see RDF::Transaction#delete_statement
    def delete_statement(statement)
      @changes.delete(statement)
      @changes.inserts.delete(statement)
      super
    end

    ##
    # Executes optimistically. If errors are encountered, we replay the buffer 
    # on the latest version.
    # 
    # If the `repository` is a transaction, we immediately replay the buffer 
    # onto it.
    #
    # @see RDF::Transaction#execute
    def execute
      raise TransactionError, 'Cannot execute a rolled back transaction. ' \
                              'Open a new one instead.' if @rolledback
      return if changes.empty?
      return super unless repository.is_a?(ActiveTriples::RDFSource)

      repository.insert(changes.inserts)
      repository.delete(changes.deletes)
    rescue RDF::Transaction::TransactionError => err
      raise err if @rolledback

      # replay changest on the current version of the repository
      repository.delete(*changes.deletes)
      repository.insert(*changes.inserts)
    end

    private
    
    def read_target
      return super unless subject
      ExtendedBoundedDescription.new(super, subject, ancestors)
    end
  end
end
