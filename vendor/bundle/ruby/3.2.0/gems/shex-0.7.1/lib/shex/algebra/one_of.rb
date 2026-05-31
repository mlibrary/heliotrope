module ShEx::Algebra
  ##
  class OneOf < Operator
    include TripleExpression
    NAME = :oneOf

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'OneOf'
      raise ArgumentError, "missing expressions in #{operator.inspect}" unless operator.has_key?('expressions')
      super
    end

    ##
    # `expr` is a OneOf and there is some shape expression `se2` in shapeExprs such that a `matches(T, se2, m)`...
    #
    # @param  (see TripleExpression#matches)
    # @return (see TripleExpression#matches)
    # @raise  (see TripleExpression#matches)
    def matches(arcs_in, arcs_out, depth: 0)
      results, satisfied, unsatisfied = [], [], []
      num_iters, max = 0, maximum

      # OneOf is greedy, and consumes triples from every sub-expression, although only one is requred it succeed. Cardinality is somewhat complicated, as if two expressions match, this works for either a cardinality of one or two. Or two passes with just one match on each pass.
      status ""
      while num_iters < max
        matched_something = expressions.select {|o| o.is_a?(TripleExpression) || o.is_a?(RDF::Resource)}.any? do |op|
          begin
            op = schema.find(op) if op.is_a?(RDF::Resource)
            matched_op = op.matches(arcs_in, arcs_out, depth: depth + 1)
            satisfied << matched_op
            results += matched_op.matched
            arcs_in -= matched_op.matched
            arcs_out -= matched_op.matched
            status "matched #{matched_op.matched.to_sxp}", depth: depth
          rescue ShEx::NotMatched => e
            status "not matched: #{e.message}", depth: depth
            unsatisfied << e.expression
            false
          end
        end
        break unless matched_something
        num_iters += 1
        status "matched #{results.length} statements after #{num_iters} iterations", depth: depth
      end

      # Max violations handled in Shape
      if num_iters < minimum
        raise ShEx::NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}"
      end

      # Last, evaluate semantic acts
      semantic_actions.each do |op|
        op.satisfies?(matched: results, depth: depth + 1)
      end unless results.empty?

      satisfy matched: results, satisfied: satisfied, depth: depth
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   ((arcs_in + arcs_out).uniq - results),
                  satisfied: satisfied, unsatisfied: unsatisfied, depth: depth
    end

    ##
    # expressions must be TripleExpressions or references to TripleExpressions
    #
    # @return [Operator] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      validate_expressions!
      super
    end
  end
end
