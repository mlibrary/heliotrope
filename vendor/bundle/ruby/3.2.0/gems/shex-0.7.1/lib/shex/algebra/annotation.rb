module ShEx::Algebra
  ##
  class Annotation < Operator
    NAME = :annotation

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Annotation"
      raise ArgumentError, "missing predicate in #{operator.inspect}" unless operator.has_key?('predicate')
      raise ArgumentError, "missing object in #{operator.inspect}" unless operator.has_key?('object')
      super
    end

    def to_h
      {
        'type' => json_type,
        'predicate' => operands.first.last.to_s,
        'object' => serialize_value(operands.last)
      }
    end
  end
end
