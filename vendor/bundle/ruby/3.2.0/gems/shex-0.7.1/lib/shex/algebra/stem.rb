module ShEx::Algebra
  ##
  class Stem < Operator::Unary
    NAME = :stem

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && %w(IriStem LiteralStem LanguageStem).include?(operator['type'])
      raise ArgumentError, "missing stem in #{operator.inspect}" unless operator.has_key?('stem')
      super
    end

    ##
    # For a node n and constraint value v, nodeSatisfies(n, v) if n matches some valueSetValue vsv in v. A term matches a valueSetValue if:
    #
    # * vsv is a Stem with stem st and nodeIn(n, st).
    def match?(value, depth: 0)
      if value.start_with?(operands.first)
        status "matched #{value}", depth: depth
        true
      else
        status "not matched #{value}", depth: depth
        false
      end
    end

    def json_type
      # FIXME: This is funky, due to oddities in normative shexj
      t = self.class.name.split('::').last
      #parent.is_a?(Value) ? "#{t}Range" : t
    end
  end

  class IriStem < Stem
    NAME = :iriStem

    # (see Stem#match?)
    def match?(value, depth: 0)
      if value.iri?
        super
      else
        status "not matched #{value.inspect} if wrong type", depth: depth
        false
      end
    end
  end

  class LiteralStem < Stem
    NAME = :literalStem

    # (see Stem#match?)
    def match?(value, depth: 0)
      if value.literal?
        super
      else
        status "not matched #{value.inspect} if wrong type", depth: depth
        false
      end
    end
  end

  class LanguageStem < Stem
    NAME = :languageStem

    # (see Stem#match?)
    # If the operand is empty, than any language will do,
    # otherwise, it matches the substring up to that first '-', if any.
    def match?(value, depth: 0)
      if value.literal? &&
         value.language? &&
         (operands.first.to_s.empty? || value.language.to_s.match?(%r(^#{operands.first}((-.*)?)$)))
        status "matched #{value}", depth: depth
        true
      else
        status "not matched #{value}", depth: depth
        false
      end
    end
  end
end
