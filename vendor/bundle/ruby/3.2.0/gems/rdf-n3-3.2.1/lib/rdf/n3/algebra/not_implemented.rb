require 'rdf'

module RDF::N3::Algebra
  #
  # A Notation3 Formula combines a graph with a BGP query.
  class NotImplemented < SPARQL::Algebra::Operator
    include RDF::N3::Algebra::Builtin

    def initialize(*args, predicate:, **options)
      raise NotImplementedError, "The #{predicate} operator is not implemented"
    end
  end
end