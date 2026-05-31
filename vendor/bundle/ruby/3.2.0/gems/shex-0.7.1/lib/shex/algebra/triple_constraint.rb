module ShEx::Algebra
  ##
  class TripleConstraint < Operator
    include TripleExpression
    NAME = :tripleConstraint

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'TripleConstraint'
      raise ArgumentError unless operator.has_key?('predicate')
      super
    end

    ##
    # In this case, we accept an array of statements, and match based on cardinality.
    #
    # @param  (see TripleExpression#matches)
    # @return (see TripleExpression#matches)
    # @raise  (see TripleExpression#matches)
    def matches(arcs_in, arcs_out, depth: 0)
      status "predicate #{predicate}", depth: depth
      results, unmatched, satisfied, unsatisfied = [], [], [], []
      num_iters, max = 0, maximum

      statements = inverse? ? arcs_in : arcs_out
      statements.select {|st| st.predicate == predicate}.each do |statement|
        break if num_iters == max # matched enough

        focus = inverse? ? statement.subject : statement.object

        begin
          matched_shape = if expression.is_a?(RDF::Resource)
            schema.enter_shape(expression, focus) do |shape|
              if shape
                shape.satisfies?(focus, depth: depth + 1)
              else
                status "Satisfy as #{expression} was re-entered for #{focus}", depth: depth
                nil
              end
            end
          elsif expression
            expression.satisfies?(focus, depth: depth + 1)
          end
          status "matched #{statement.to_sxp}", depth: depth
          if matched_shape
            matched_shape.matched = [statement]
            statement = statement.dup.extend(ReferencedStatement)
            statement.referenced = matched_shape
            satisfied << matched_shape
          end
          results << statement
          num_iters += 1
        rescue ShEx::NotSatisfied => e
          status "not satisfied: #{e.message}", depth: depth
          unsatisfied << e.expression
          statement = statement.dup.extend(ReferencedStatement)
          statement.referenced = expression
          unmatched << statement
        end
      end

      # Max violations handled in Shape
      if results.length < minimum
        raise ShEx::NotMatched, "Minimum Cardinality Violation: #{results.length} < #{minimum}"
      end

      # Last, evaluate semantic acts
      semantic_actions.each do |op|
        op.satisfies?(results, matched: results, depth: depth + 1)
      end unless results.empty?

      satisfy matched:   results,   unmatched:   unmatched,
              satisfied: satisfied, unsatisfied: unsatisfied, depth: depth
    rescue ShEx::NotMatched, ShEx::NotSatisfied => e
      not_matched e.message,
                  matched:   results,   unmatched:   unmatched,
                  satisfied: satisfied, unsatisfied: unsatisfied, depth: depth
    end

    def predicate
      @predicate ||= operands.detect {|o| o.is_a?(Array) && o.first == :predicate}.last
    end

    ##
    # expression must be a ShapeExpression
    #
    # @return [Operator] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      case expression
      when nil, ShapeExpression
      when RDF::Resource
        ref = schema.find(expression)
        ref.is_a?(ShapeExpression) ||
        structure_error("#{json_type} must reference a ShapeExpression: #{ref}")
      else
        structure_error("#{json_type} must be a ShapeExpression or reference: #{expresson.to_sxp}")
      end
      super
    end

    ##
    # Included TripleConstraints
    # @return [Array<TripleConstraints>]
    def triple_constraints
      [self]
    end

    def inverse?
      operands.include?(:inverse)
    end
  end
end
