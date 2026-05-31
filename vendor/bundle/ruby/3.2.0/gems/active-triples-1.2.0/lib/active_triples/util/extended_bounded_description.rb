module ActiveTriples
  ##
  # Bounds the scope of an `RDF::Queryable` to a subgraph defined from a source 
  # graph, a starting node, and a list of "ancestors" terms, by the following 
  # process:
  #
  # Include in the subgraph:
  #  1. All statements in the source graph where the subject of the statement 
  #     is the starting node.
  #  2. Add the starting node to the ancestors list.
  #  2. Recursively, for all statements already in the subgraph, include in 
  #     the subgraph the Extended Bounded Description for each object node, 
  #     unless the object is in the ancestors list.
  #
  # The list of "ancestors" is empty by default. 
  #
  # This subgraph this process yields can be considered as a description of 
  # the starting node.
  #
  # Compare to Concise Bounded Description 
  # (https://www.w3.org/Submission/CBD/), the common subgraph scope used for 
  # SPARQL DESCRIBE queries.
  #
  # @note this implementation requires that the `source_graph` remain unchanged 
  #   while iterating over the description. The safest way to achive this is to 
  #   use an immutable `RDF::Dataset` (e.g. a `Repository#snapshot`).
  class ExtendedBoundedDescription
    include RDF::Enumerable
    include RDF::Queryable
    
    ##
    # @!attribute ancestors [r]
    #   @return Array<RDF::Term>
    # @!attribute source_graph [r]
    #   @return RDF::Queryable
    # @!attribute starting_node [r]
    #   @return RDF::Term
    attr_reader  :ancestors, :source_graph, :starting_node

    ##
    # By analogy to Concise Bounded Description.
    #
    # @param source_graph  [RDF::Queryable]
    # @param starting_node [RDF::Term]
    # @param ancestors     [Array<RDF::Term>] default: []
    def initialize(source_graph, starting_node, ancestors = [])
      @source_graph  = source_graph
      @starting_node = starting_node
      @ancestors     = ancestors
    end
    
    ##
    # @see RDF::Enumerable#each
    def each_statement
      ancestors = @ancestors.dup

      if block_given?
        statements = source_graph.query([starting_node, nil, nil]).each
        statements.each_statement { |st| yield st }
        
        ancestors << starting_node
        
        statements.each_object do |object|
          next if object.literal?  || ancestors.include?(object)
          ExtendedBoundedDescription
            .new(source_graph, object, ancestors).each do |statement|
            yield statement
          end
        end
      end
      enum_statement
    end
    alias_method :each, :each_statement
  end
end
