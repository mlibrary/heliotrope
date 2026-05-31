module ShEx::Algebra
  ##
  class Or < Operator
    include ShapeExpression
    NAME = :or

    def initialize(*args, **options)
      case
      when args.length < 2
        raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 2..)"
      end

      # All arguments must be ShapeExpression
      raise ArgumentError, "All operands must be Shape operands or resource" unless args.all? {|o| o.is_a?(ShapeExpression) || o.is_a?(RDF::Resource)}
      super
    end

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'ShapeOr'
      raise ArgumentError, "missing shapeExprs in #{operator.inspect}" unless operator.is_a?(Hash) && operator.has_key?('shapeExprs')
      super
    end

    #
    # S is a ShapeOr and there is some shape expression se2 in shapeExprs such that satisfies(n, se2, G, m).
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    def satisfies?(focus, depth: 0)
      status "", depth: depth
      unsatisfied = []
      expressions.any? do |op|
        begin
          matched_op = case op
          when RDF::Resource
            schema.enter_shape(op, focus) do |shape|
              if shape
                shape.satisfies?(focus, depth: depth + 1)
              else
                status "Satisfy as #{op} was re-entered for #{focus}", depth: depth
                shape
              end
            end
          when ShapeExpression
            op.satisfies?(focus, depth: depth + 1)
          end
          return satisfy focus: focus, satisfied: matched_op, depth: depth
        rescue ShEx::NotSatisfied => e
          status "unsatisfied #{focus}", depth: depth
          op = op.dup
          if op.respond_to?(:satisfied)
            op.satisfied = e.expression.satisfied
            op.unsatisfied = e.expression.unsatisfied
          end
          unsatisfied << op
          status "unsatisfied: #{e.message}", depth: depth
          false
        end
      end

      not_satisfied "Expected some expression to be satisfied",
                    focus: focus, unsatisfied: unsatisfied, depth: depth
    end

    ##
    # expressions must be ShapeExpressions or references to ShapeExpressions
    #
    # @return [Operator] `self`
    # @raise  [ShEx::StructureError] if the value is invalid
    def validate!
      validate_expressions!
      validate_self_references!
      super
    end

    def json_type
      "ShapeOr"
    end
  end
end
