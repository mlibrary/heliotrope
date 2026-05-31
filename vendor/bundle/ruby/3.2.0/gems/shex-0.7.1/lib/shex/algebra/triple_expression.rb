require 'sparql/algebra'

module ShEx::Algebra
  # Implements `neigh`, `arcs_out`, `args_in` and `matches`
  module TripleExpression
    ##
    # `matches`: asserts that a triple expression is matched by a set of triples that come from the neighbourhood of a node in an RDF graph. The expression `matches(T, expr, m)` indicates that a set of triples `T` can satisfy these rules...
    #
    # Behavior should be overridden in subclasses, which end by calling this through `super`.
    #
    # @param [Array<RDF::Statement>] arcs_in
    # @param [Array<RDF::Statement>] arcs_out
    # @return [TripleExpression] with `matched` accessor for matched triples
    # @raise [ShEx::NotMatched] with `expression` accessor to access `matched` and `unmatched` statements along with `satisfied` and `unsatisfied` operations.
    def matches(arcs_in, arcs_out, depth: 0)
      raise NotImplementedError, "#matches Not implemented in #{self.class}"
    end

    ##
    # expressions must be TripleExpressions or references to TripleExpressions
    #
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate_expressions!
      expressions.each do |op|
        case op
        when TripleExpression
        when RDF::Resource
          ref = schema.find(op)
          ref.is_a?(TripleExpression) ||
          structure_error("#{json_type} must reference a TripleExpression: #{ref}")
        else
          structure_error("#{json_type} must be a TripleExpression or reference: #{op.to_sxp}")
        end
      end
    end

    ##
    # Included TripleConstraints
    # @return [Array<TripleConstraints>]
    def triple_constraints
      @triple_contraints ||= operands.select do |o|
        o.is_a?(TripleExpression)
      end.
      map(&:triple_constraints).
      flatten.
      uniq
    end

    ##
    # Minimum constraint (defaults to 1)
    # @return [Integer]
    def minimum
      @minimum ||= begin
        op = operands.detect {|o| o.is_a?(Array) && o.first == :min} || [:min, 1]
        op[1]
      end
    end

    ##
    # Maximum constraint (defaults to 1)
    # @return [Integer, Float::INFINITY]
    def maximum
      @maximum ||= begin
        op = operands.detect {|o| o.is_a?(Array) && o.first == :max} || [:max, 1]
        op[1] == '*' ? Float::INFINITY : op[1]
      end
    end

    # This operator includes TripleExpression
    def triple_expression?; true; end
  end

  module ReferencedStatement
    # @return [ShEx::Algebra::ShapeExpression] referenced operand which satisfied some of this statement
    attr_accessor :referenced

    def to_sxp_bin
      referenced ? super + [referenced.to_sxp_bin] : super
    end
  end
end
