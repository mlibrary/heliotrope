module LD::Patch::Algebra

  ##
  # The LD Patch `bind` operator.
  #
  # The Bind operation is used to bind a single term to a variable.
  #
  # @example simple value to variable binding
  #   Bind ?x <http://example.org/s> . #=>
  #   (bind ?x <http://example.org/s> ())
  #
  # @example constant path (filter-forward.ldpatch)
  #   Bind ?x <http://example.org/s> / <http://example.org/p1> . #=>
  #   (bind ?x <http://example.org/s> (<http://example.org/p1>))
  #
  # @example list index (path-at.ldpatch)
  #   Bind ?x <http://example.org/s> / 1 . #=>
  #   (bind ?x <http://example.org/s> ((index 1)))
  #
  # @example reverse (path-backward.ldpath)
  #   Bind ?x <http://example.org/s> / ^<http://example.org/p1> . #=>
  #   (bind ?x <http://example.org/s> ((reverse <http://example.org/p1>)))
  #
  # @example constraint (path-filter-equal.ldpatch)
  #   Bind ?x <http://example.org/s> / <http://example.org/p2> [  / <http://example.org/l> = "b" ] . #=>
  #   (bind ?x <http://example.org/s> (
  #     <http://example.org/p2>
  #     (constraint (<http://example.org/l>) "b")))
  #
  # @example constraint (path-filter.ldpatch)
  #   Bind ?x <http://example.org/s> / <http://example.org/p2> [  / <http://example.org/p1> ] . #=>
  #   (bind ?x <http://example.org/s> (
  #     <http://example.org/p2>
  #     (constraint (<http://example.org/l>))))
  #
  # @example starting with a literal
  #   Bind ?x "a" / ^<http://example.org/l> / ^<http://example.org/p2> . #=>
  #   (bind ?x "a" (
  #     (reverse <http://example.org/l>)
  #     (reverse <http://example.org/p2>)))
  #
  # @example unicity (path-unicity.ldpath)
  #   Bind ?x <http://example.org/s> / <http://example.org/p1> ! . #=>
  #   SELECT ?x
  #   WHERE {<http//example.org/s> <http://example.org/p1> ?x}
  #   GROUP BY ?x
  #   HAVING COUNT(?x) = 1
  #   (bind ?x ?0
  #     ((pattern <http://example.org/s> <http://example.org/p1> ??0)
  #      (unique ??0)))
  class Bind < SPARQL::Algebra::Operator::Ternary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Evaluatable

    NAME = :bind

    ##
    # Maps the value to a single output term by executing the path and updates `bindings` with `var` set to that output term
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [RDF::Query::Solutions] :bindings
    # @return [RDF::Query::Solutions] A single solution including passed bindings with `var` bound to the solution.
    # @raise [Error]
    #   If path does not evaluate to a single term or if unbound variables are used.
    # @see    http://www.w3.org/TR/sparql11-update/
    def execute(queryable, options = {})
      debug(options) {"Bind"}
      bindings = options.fetch(:bindings)
      solution = bindings.first
      var, value, path = operands

      # Bind variables to path
      if value.variable?
        raise LD::Patch::Error.new("Operand uses unbound variable #{value.inspect}", code: 400) unless solution.bound?(value)
        value = solution[value]
      end

      path = path.dup.replace_vars! do |v|
        raise Error, "Operand uses unbound variable #{v.inspect}" unless solution.bound?(v)
        solution[v]
      end
      results = path.execute(queryable, terms: [value])
      raise LD::Patch::Error, "Bind path bound to #{results.length} terms, expected just one" unless results.length == 1
      RDF::Query::Solutions.new [solution.merge(var.to_sym => results.first.path)]
    end
  end
end