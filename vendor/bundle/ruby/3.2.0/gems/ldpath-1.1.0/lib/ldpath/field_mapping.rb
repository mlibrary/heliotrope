module Ldpath
  class FieldMapping
    attr_reader :name, :selector, :field_type

    def initialize(name:, selector:, field_type: nil, options: {})
      @name = name.to_s
      @selector = selector
      @field_type = field_type
      @options = options
    end

    def evaluate(program, uri, context)
      case selector
      when Ldpath::Selector
        return to_enum(:evaluate, program, uri, context) unless block_given?

        selector.evaluate(program, uri, context).each do |value|
          yield transform_value(value)
        end
      when RDF::Literal
        Array(selector.canonicalize.object)
      else
        Array(selector)
      end
    end

    private

    def transform_value(value)
      v = if value.is_a? RDF::Literal
            value.canonicalize.object
          else
            value
          end

      if field_type
        RDF::Literal.new(v.to_s, datatype: field_type).canonicalize.object
      else
        v
      end
    end
  end
end
