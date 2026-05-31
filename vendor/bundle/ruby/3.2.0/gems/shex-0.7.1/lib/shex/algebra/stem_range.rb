module ShEx::Algebra
  ##
  class StemRange < Operator::Binary
    NAME = :stemRange

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && %w(IriStemRange LiteralStemRange LanguageStemRange).include?(operator['type'])
      raise ArgumentError, "missing stem in #{operator.inspect}" unless operator.has_key?('stem')

      # Normalize wildcard representation
      operator['stem'] = :wildcard if operator['stem'] =={'type' => 'Wildcard'}

      # Note that the type may be StemRange, but if there's no exclusions, it's really just a Stem
      if operator.has_key?('exclusions')
        super
      else
        # Remove "Range" from type
        case operator['type']
        when 'IriStemRange'
          IriStem.from_shexj(operator.merge('type' => 'IriStem'), **options)
        when 'LiteralStemRange'
          LiteralStem.from_shexj(operator.merge('type' => 'LiteralStem'), **options)
        when 'LanguageStemRange'
          LanguageStem.from_shexj(operator.merge('type' => 'LanguageStem'), **options)
        end
      end
    end

    ##
    # For a node n and constraint value v, nodeSatisfies(n, v) if n matches some valueSetValue vsv in v. A term matches a valueSetValue if:
    #
    # * vsv is a StemRange with stem st and exclusions excls and nodeIn(n, st) and there is no x in excls such that nodeIn(n, excl).
    # * vsv is a Wildcard with exclusions excls and there is no x in excls such that nodeIn(n, excl).
    def match?(value, depth: 0)
      initial_match = case operands.first
      when :wildcard then true
      when RDF::Value then value.start_with?(operands.first)
      else false
      end

      unless initial_match
        status "#{value} does not match #{operands.first}", depth: depth
        return false
      end

      if exclusions.any? do |exclusion|
          case exclusion
          when RDF::Value then value == exclusion
          when Stem       then exclusion.match?(value, depth: depth + 1)
          else                 false
          end
        end
        status "#{value} excluded", depth: depth
        return false
      end

      status "matched #{value}", depth: depth
      true
    end

    def exclusions
      (operands.last.is_a?(Array) && operands.last.first == :exclusions) ? operands.last[1..-1] : []
    end
  end

  class IriStemRange < StemRange
    NAME = :iriStemRange

    # (see StemRange#match?)
    def match?(value, depth: 0)
      if value.uri?
        super
      else
        status "not matched #{value.inspect} if wrong type", depth: depth
        false
      end
    end
  end

  class LiteralStemRange < StemRange
    NAME = :literalStemRange

    # (see StemRange#match?)
    def match?(value, depth: 0)
      if value.literal?
        super
      else
        status "not matched #{value.inspect} if wrong type", depth: depth
        false
      end
    end
  end

  class LanguageStemRange < StemRange
    NAME = :languageStemRange

    # (see StemRange#match?)
    def match?(value, depth: 0)
      initial_match = case operands.first
      when :wildcard then true
      when RDF::Literal
        value.language? &&
        (operands.first.to_s.empty? || value.language.to_s.match?(%r(^#{operands.first}((-.*)?)$)))
      else false
      end

      unless initial_match
        status "#{value} does not match #{operands.first}", depth: depth
        return false
      end

      if exclusions.any? do |exclusion|
          case exclusion
          when RDF::Literal, String then value.language.to_s == exclusion
          when Stem                 then exclusion.match?(value, depth: depth + 1)
          else                           false
          end
        end
        status "#{value} excluded", depth: depth
        return false
      end

      status "matched #{value}", depth: depth
      true
    end
  end
end
