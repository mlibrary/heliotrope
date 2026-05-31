module ShEx::Algebra
  ##
  class Shape < Operator
    include ShapeExpression
    NAME = :shape

    ##
    # Let `outs` be the `arcsOut` in `remainder`: `outs = remainder ∩ arcsOut(G, n)`.
    # @return [Array<RDF::Statement>]
    attr_accessor :outs

    ##
    # Let `matchables` be the triples in `outs` whose predicate appears in a {TripleConstraint} in `expression`. If `expression` is absent, `matchables = Ø` (the empty set).
    # @return [Array<RDF::Statement>]
    attr_accessor :matchables

    ##
    # Let `unmatchables` be the triples in `outs` which are not in `matchables`. `matchables ∪ unmatchables = outs.`
    # @return [Array<RDF::Statement>]
    attr_accessor :unmatchables

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Shape"
      super
    end

    # The `satisfies` semantics for a `Shape` depend on a matches function defined below. For a node `n`, shape `S`, graph `G`, and shapeMap `m`, `satisfies(n, S, G, m)`.
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    def satisfies?(focus, depth: 0)
      # neigh(G, n) is the neighbourhood of the node n in the graph G.
      #
      #    neigh(G, n) = arcsOut(G, n) ∪ arcsIn(G, n)
      arcs_in = schema.graph.query({object: focus}).to_a.sort_by(&:to_sxp)
      arcs_out = schema.graph.query({subject: focus}).to_a.sort_by(&:to_sxp)
      neigh = (arcs_in + arcs_out).uniq

      # `matched` is the subset of statements which match `expression`.
      status("arcsIn: #{arcs_in.count}, arcsOut: #{arcs_out.count}", depth: depth)
      matched_expression = case expression
      when RDF::Resource
        ref.matches(arcs_in, arcs_out, depth: depth + 1)
      when TripleExpression
        expression.matches(arcs_in, arcs_out, depth: depth + 1)
      end
      matched = Array(matched_expression && matched_expression.matched)

      # `remainder` is the set of unmatched statements
      remainder = neigh - matched

      # Let `outs` be the `arcsOut` in `remainder`: `outs = remainder ∩ arcsOut(G, n)`.
      @outs = remainder.select {|s| s.subject == focus}

      # Let `matchables` be the triples in `outs` whose predicate appears in a `TripleConstraint` in `expression`. If `expression` is absent, `matchables = Ø` (the empty set).
      predicates = expression ? expression.triple_constraints.map(&:predicate).uniq : []
      @matchables = outs.select {|s| predicates.include?(s.predicate)}

      # Let `unmatchables` be the triples in `outs` which are not in `matchables`.
      @unmatchables = outs - matchables

      # No matchable can be matched by any TripleConstraint in expression
      unmatched = matchables.select do |statement|
        expression.triple_constraints.any? do |expr|
          begin
            statement.predicate == expr.predicate && expr.matches([], [statement], depth: depth + 1)
          rescue ShEx::NotMatched
            false # Expected not to match
          end
        end if expression
      end
      unless unmatched.empty?
        not_satisfied "Statements remain matching TripleConstraints",
                      matched: matched,
                      unmatched: unmatched,
                      satisfied: expression,
                      depth: depth
      end

      # There is no triple in matchables whose predicate does not appear in extra.
      unmatched = matchables.reject {|st| extra.include?(st.predicate)}
      unless unmatched.empty?
        not_satisfied "Statements remains with predicate #{unmatched.map(&:predicate).compact.join(',')} not in extra",
                      matched: matched,
                      unmatched: unmatched,
                      satisfied: expression,
                      depth: depth
      end

      # closed is false or unmatchables is empty.
      not_satisfied "Unmatchables remain on a closed shape", depth: depth unless !closed? || unmatchables.empty?

      # Presumably, to be satisfied, there must be some triples in matches
      semantic_actions.each do |op|
        op.satisfies?(matched, matched: matched, depth: depth + 1)
      end unless matched.empty?

      # FIXME: also record matchables, outs and others?
      satisfy focus: focus, matched: matched, depth: depth
    rescue ShEx::NotMatched => e
      not_satisfied e.message, focus: focus, unsatisfied: e.expression, depth: depth
    end

    ##
    # expression must be a TripleExpression and must not reference itself recursively.
    #
    # @return [Operator] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      case expression
      when nil, TripleExpression
      when RDF::Resource
        ref = schema.find(expression)
        ref.is_a?(TripleExpression) ||
        structure_error("#{json_type} must reference a TripleExpression: #{ref}")
      else
        structure_error("#{json_type} must be a TripleExpression or reference: #{expression.to_sxp}")
      end
      # FIXME: this runs afoul of otherwise legitamate self-references, through a TripleExpression.
      #!validate_self_references!
      super
    end

    private
    # There may be multiple extra operands
    def extra
      operands.select {|op| op.is_a?(Array) && op.first == :extra}.inject([]) do |memo, ary|
        memo + Array(ary[1..-1])
      end.uniq
    end
  end
end
