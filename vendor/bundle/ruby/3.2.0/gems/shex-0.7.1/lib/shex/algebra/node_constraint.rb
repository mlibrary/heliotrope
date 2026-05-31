# -*- encoding: utf-8 -*-
module ShEx::Algebra
  ##
  class NodeConstraint < Operator
    include ShapeExpression
    NAME = :nodeConstraint

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == 'NodeConstraint'
      super
    end

    #
    # S is a NodeConstraint and satisfies2(focus, se) as described below in Node Constraints. Note that testing if a node satisfies a node constraint does not require a graph or shapeMap.
    # @param  (see ShapeExpression#satisfies?)
    # @return (see ShapeExpression#satisfies?)
    # @raise  (see ShapeExpression#satisfies?)
    def satisfies?(focus, depth: 0)
      status "", depth: depth
      satisfies_node_kind?(focus, depth: depth + 1) &&
      satisfies_datatype?(focus, depth: depth + 1) &&
      satisfies_string_facet?(focus, depth: depth + 1) &&
      satisfies_numeric_facet?(focus, depth: depth + 1) &&
      satisfies_values?(focus, depth: depth + 1) &&
      satisfy(depth: depth)
    end

  private

    ##
    # Satisfies Node Kind Constraint
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_node_kind?(value, depth: 0)
      kind = case operands.detect {|o| o.is_a?(Symbol)}
      when :iri         then RDF::URI
      when :bnode       then RDF::Node
      when :literal     then RDF::Literal
      when :nonliteral  then RDF::Resource
      else              return true
      end

      not_satisfied "Node was #{value.inspect} expected kind #{kind}", depth: depth unless
        value.is_a?(kind)
      status "right kind: #{value}: #{kind}", depth: depth
      true
    end

    ##
    # Datatype Constraint
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_datatype?(value, depth: 0)
      dt = op_fetch(:datatype)
      return true unless dt

      not_satisfied "Node was #{value.inspect}, expected datatype #{dt}", depth: depth unless
        value.is_a?(RDF::Literal) && value.datatype == RDF::URI(dt) && value.valid?
      status "right datatype: #{value}: #{dt}", depth: depth
      true
    end

    ##
    # String Facet Constraint
    # Checks all length/minlength/maxlength/pattern facets against the string representation of the value.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    # @todo using the XPath regexp engine supports additional flags "s" and "q"
    def satisfies_string_facet?(value, depth: 0)
      length    = op_fetch(:length)
      minlength = op_fetch(:minlength)
      maxlength = op_fetch(:maxlength)
      pat = (operands.detect {|op| op.is_a?(Array) && op[0] == :pattern} || [])
      pattern = pat[1]

      flags = 0
      flags |= Regexp::EXTENDED   if pat[2].to_s.include?("x")
      flags |= Regexp::IGNORECASE if pat[2].to_s.include?("i")
      flags |= Regexp::MULTILINE  if pat[2].to_s.include?("m")

      return true if (length || minlength || maxlength || pattern).nil?

      v_s = case value
      when RDF::Node then value.id
      else value.to_s
      end

      not_satisfied "Node #{v_s.inspect} length not #{length}", depth: depth if
        length && v_s.length != length.to_i
      not_satisfied"Node #{v_s.inspect} length < #{minlength}", depth: depth if
        minlength && v_s.length < minlength.to_i
      not_satisfied "Node #{v_s.inspect} length > #{maxlength}", depth: depth if
        maxlength && v_s.length > maxlength.to_i
      not_satisfied "Node #{v_s.inspect} does not match #{pattern}", depth: depth if
        pattern && !Regexp.new(pattern, flags).match(v_s)
      status "right string facet: #{value}", depth: depth
      true
    end

    ##
    # Numeric Facet Constraint
    # Checks all numeric facets against the value.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_numeric_facet?(value, depth: 0)
      mininclusive   = op_fetch(:mininclusive)
      minexclusive   = op_fetch(:minexclusive)
      maxinclusive   = op_fetch(:maxinclusive)
      maxexclusive   = op_fetch(:maxexclusive)
      totaldigits    = op_fetch(:totaldigits)
      fractiondigits = op_fetch(:fractiondigits)

      return true if (mininclusive || minexclusive || maxinclusive || maxexclusive || totaldigits || fractiondigits).nil?

      not_satisfied "Node #{value.inspect} not numeric", depth: depth unless
        value.is_a?(RDF::Literal::Numeric)

      not_satisfied "Node #{value.inspect} not decimal", depth: depth if
        (totaldigits || fractiondigits) && (!value.is_a?(RDF::Literal::Decimal) || value.invalid?)

      numeric_value = value.object
      case
      when !mininclusive.nil? && numeric_value < mininclusive.object then not_satisfied("Node #{value.inspect} < #{mininclusive.object}", depth: depth)
      when !minexclusive.nil? && numeric_value <= minexclusive.object then not_satisfied("Node #{value.inspect} not <= #{minexclusive.object}", depth: depth)
      when !maxinclusive.nil? && numeric_value > maxinclusive.object then not_satisfied("Node #{value.inspect} > #{maxinclusive.object}", depth: depth)
      when !maxexclusive.nil? && numeric_value >= maxexclusive.object then not_satisfied("Node #{value.inspect} >= #{maxexclusive.object}", depth: depth)
      when !totaldigits.nil?
        md = value.canonicalize.to_s.match(/([1-9]\d*|0)?(?:\.(\d+)(?!0))?/)
        digits = md ? (md[1].to_s + md[2].to_s) : ""
        if digits.length > totaldigits.to_i
          not_satisfied "Node #{value.inspect} total digits != #{totaldigits}", depth: depth
        end
      when !fractiondigits.nil?
        md = value.canonicalize.to_s.match(/\.(\d+)(?!0)?/)
        num = md ? md[1].to_s : ""
        if num.length > fractiondigits.to_i
          not_satisfied "Node #{value.inspect} fractional digits != #{fractiondigits}", depth: depth
        end
      end
      status "right numeric facet: #{value}", depth: depth
      true
    end

    ##
    # Value Constraint
    # Checks all numeric facets against the value.
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies_values?(value, depth: 0)
      values = operands.select {|op| op.is_a?(Value)}
      return true if values.empty?
      matched_value = values.detect {|v| v.match?(value, depth: depth + 1)}
      not_satisfied "Value #{value.to_sxp} not expected, wanted #{values.to_sxp}", depth: depth unless matched_value
      status "right value: #{value}", depth: depth
      true
    end

    # Returns the value of a particular facet
    def op_fetch(which)
      (operands.detect {|op| op.is_a?(Array) && op[0] == which} || [])[1]
    end
  end
end
