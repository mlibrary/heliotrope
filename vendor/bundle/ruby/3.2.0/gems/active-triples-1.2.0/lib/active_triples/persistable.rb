# frozen_string_literal: true
module ActiveTriples
  ##
  # Bundles the core interfaces used by ActiveTriples persistence strategies
  # to treat a graph as persistable. Specificially:
  #
  #   - RDF::Enumerable
  #   - RDF::Mutable
  #
  # @abstract implement {#graph} as a reference to an `RDF::Graph` or similar.
  module Persistable
    extend ActiveSupport::Concern

    include RDF::Enumerable
    include RDF::Mutable

    ##
    # This gives the {RDF::Graph} which represents the current state of this
    # resource.
    #
    # @return [RDF::Graph] the underlying graph representation of the
    #   `RDFSource`.
    #
    # @see http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/#change-over-time
    #   RDF Concepts and Abstract Syntax comment on "RDF source"
    def graph
      persistence_strategy.graph
    end

    # @see RDF::Writable.insert_statement
    def insert_statement(*args)
      graph.send(:insert_statement, *args)
    end

    ##
    # @see RDF::Writable.delete_statement
    def delete_statement(*args)
      graph.send(:delete_statement, *args)
    end

    ##
    # Returns the persistence strategy object that handles this object's
    # persistence
    def persistence_strategy
      @persistence_strategy || set_persistence_strategy(RepositoryStrategy)
    end

    ##
    # Sets a persistence strategy
    #
    # @param klass [Class] A class implementing the persistence strategy
    #   interface
    def set_persistence_strategy(klass)
      @persistence_strategy = klass.new(self)
    end

    ##
    # Removes the statements in this RDFSource's graph from the persisted graph
    #
    # @return [Boolean]
    def destroy
      persistence_strategy.destroy
    end
    alias_method :destroy!, :destroy

    ##
    # @return [Boolean] true if this item is destroyed
    def destroyed?
      persistence_strategy.destroyed?
    end

    ##
    # Sends a persistence message to the `persistence_startegy`, saving the
    # `Persistable`.
    #
    # @return [Boolean]
    def persist!(opts={})
      result = false
      return result if opts[:validate] && !valid?
      run_callbacks :persist do
        result = persistence_strategy.persist!
      end
      result
    end

    ##
    # Indicates if the resource is persisted.
    #
    # @see #persist
    # @return [Boolean]
    def persisted?
      persistence_strategy.persisted?
    end

    ##
    # Repopulates the graph according to the persistence strategy
    #
    # @return [Boolean]
    def reload
      @term_cache ||= {}
      persistence_strategy.reload
    end
  end
end
