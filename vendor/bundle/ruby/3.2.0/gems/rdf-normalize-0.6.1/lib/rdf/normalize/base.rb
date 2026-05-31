module RDF::Normalize
  ##
  # Abstract class for pluggable normalization algorithms. Delegates to a default or selected algorithm if instantiated
  class Base
    attr_reader :dataset

    # Enumerates normalized statements
    #
    # @yield statement
    # @yieldparam [RDF::Statement] statement
    def each(&block)
      raise "Not Implemented"
    end

    # Returns a map from input blank node identifiers to canonical blank node identifiers.
    #
    # @return [Hash{String => String}]
    def to_hash
      raise "Not Implemented"
    end
  end
end