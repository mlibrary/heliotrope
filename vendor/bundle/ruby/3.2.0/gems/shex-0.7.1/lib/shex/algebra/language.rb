module ShEx::Algebra
  ##
  class Language < Operator::Unary
    NAME = :language

    ##
    # matches any literal having a language tag that matches value
    def match?(value, depth: 0)
      status "", depth: depth
      if case expr = operands.first
        when RDF::Literal then value.language == expr.to_s.to_sym
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
