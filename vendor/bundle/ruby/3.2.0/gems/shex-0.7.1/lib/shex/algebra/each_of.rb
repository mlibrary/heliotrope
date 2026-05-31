module ShEx::Algebra
  ##
  class EachOf < Operator
    include TripleExpression
    NAME = :eachOf

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'EachOf'
      raise ArgumentError, "missing expressions in #{operator.inspect}" unless operator.has_key?('expressions')
      super
    end

    ##
    # expr is an EachOf and there is some partition of T into T1, T2,… such that for every expression expr1, expr2,… in shapeExprs, matches(Tn, exprn, m)...
    #
    # @param  (see TripleExpression#matches)
    # @return (see TripleExpression#matches)
    # @raise  (see TripleExpression#matches)
    def matches(arcs_in, arcs_out, depth: 0)
      status "", depth: depth
      results, satisfied, unsatisfied = [], [], []
      num_iters, max = 0, maximum

      # enter semantic acts
      semantic_actions.each {|op| op.enter(arcs_in: arcs_in, arcs_out: arcs_out, depth: depth + 1)}

      while num_iters < max
        begin
          matched_this_iter = []
          expressions.select {|o| o.is_a?(TripleExpression) || o.is_a?(RDF::Resource)}.all? do |op|
            begin
              op = schema.find(op) if op.is_a?(RDF::Resource)
              matched_op = op.matches(arcs_in - matched_this_iter, arcs_out - matched_this_iter, depth: depth + 1)
              satisfied << matched_op
              matched_this_iter += matched_op.matched
            rescue ShEx::NotMatched => e
              status "not matched: #{e.message}", depth: depth
              unsatisfied << e.expression
              raise
            end
          end
          results += matched_this_iter
          arcs_in -= matched_this_iter
          arcs_out -= matched_this_iter
          num_iters += 1
          status "matched #{results.length} statements after #{num_iters} iterations", depth: depth
        rescue ShEx::NotMatched => e
          status "no match after #{num_iters} iterations (ignored)", depth: depth
          break
        end
      end

      # Max violations handled in Shape
      if num_iters < minimum
        raise ShEx::NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}"
      end

      # Last, evaluate semantic acts
      semantic_actions.each {|op| op.satisfies?(nil, matched: results, depth: depth + 1)}

      satisfy matched: results, satisfied: satisfied, depth: depth
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   ((arcs_in + arcs_out).uniq - results),
                  satisfied: satisfied, unsatisfied: unsatisfied,
                  depth:     depth
    ensure
      semantic_actions.each {|op| op.exit(matched: matched, depth: depth + 1)}
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
