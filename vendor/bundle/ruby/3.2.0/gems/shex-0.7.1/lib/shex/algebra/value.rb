module ShEx::Algebra
  ##
  class Value < Operator::Unary
    NAME = :value

    ##
    # For a node n and constraint value v, nodeSatisfies(n, v) if n matches some valueSetValue vsv in v. A term matches a valueSetValue if:
    #
    # * vsv is an objectValue and n = vsv.
    # * vsv is a Stem with stem st and nodeIn(n, st).
    # * vsv is a StemRange with stem st and exclusions excls and nodeIn(n, st) and there is no x in excls such that nodeIn(n, excl).
    # * vsv is a Wildcard with exclusions excls and there is no x in excls such that nodeIn(n, excl).
    def match?(value, depth: 0)
      status "", depth: depth
      if case expr = operands.first
        when RDF::Value then value.eql?(expr)
        when Language, Stem, StemRange then expr.match?(value, depth: depth + 1)
        else false
        end
        status "matched #{value}", depth: depth
        true
      else
        status "not matched #{value}", depth: depth
        false
      end
    end
  end
end
