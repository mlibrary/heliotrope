module ShEx::Algebra
  ##
  class And < Operator
    include ShapeExpression
    NAME = :and

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
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'ShapeAnd'
      raise ArgumentError, "missing shapeExprs in #{operator.inspect}" unless operator.has_key?('shapeExprs')
      super
    end

    #
    # S is a ShapeAnd and for every shape expression se2 in shapeExprs, satisfies(n, se2, G, m).
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    def satisfies?(focus, depth: 0)
      status ""
      satisfied = []
      unsatisfied = expressions.dup

      # Operand raises NotSatisfied, so no need to check here.
      expressions.each do |op|
        satisfied << case op
        when RDF::Resource
          schema.enter_shape(op, focus) do |shape|
            if shape
              shape.satisfies?(focus, depth: depth + 1)
            else
              status "Satisfy as #{op} was re-entered for #{focus}", depth: depth
            end
          end
        when ShapeExpression
          op.satisfies?(focus, depth: depth + 1)
        end
        unsatisfied.shift
      end
      satisfy focus: focus, satisfied: satisfied, depth: depth
    rescue ShEx::NotSatisfied => e
      not_satisfied e.message,
                    focus:       focus, 
                    satisfied:   satisfied,
                    unsatisfied: unsatisfied,
                    depth:       depth
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
      "ShapeAnd"
    end
  end
end
