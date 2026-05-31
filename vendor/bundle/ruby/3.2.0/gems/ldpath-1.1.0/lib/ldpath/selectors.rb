module Ldpath
  class Selector
    def evaluate(program, uris, context)
      return to_enum(:evaluate, program, uris, context) unless block_given?
      enum_wrap(uris).map do |uri|
        loading program, uri, context
        enum_flatten_one(evaluate_one(uri, context)).each do |x|
          yield x unless x.nil?
        end
      end
    end

    def loading(program, uri, context)
      program.loading uri, context
    end

    protected

    def enum_wrap(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      elsif object.is_a? Hash
        [object]
      elsif object.is_a? Enumerable
        object
      else
        [object]
      end
    end
    
    def enum_flatten_one(object)
      return to_enum(:enum_flatten_one, object) unless block_given?

      enum_wrap(object).each do |e|
        enum_wrap(e).each do |v|
          yield v
        end
      end
    end
  end

  class SelfSelector < Selector
    def evaluate_one(uri, _context)
      uri
    end
  end

  class FunctionSelector < Selector
    attr_reader :fname, :arguments

    def initialize(fname, arguments = [])
      @fname = fname
      @arguments = Array(arguments)
    end

    def evaluate(program, uris, context)
      return to_enum(:evaluate, program, uris, context) unless block_given?

      enum_wrap(uris).map do |uri|
        loading program, uri, context
        args = arguments.map do |i|
          case i
          when Selector
            i.evaluate(program, uri, context)
          else
            i
          end
        end
        enum_flatten_one(program.func_call(fname, uri, context, *args)).each do |x|
          yield x unless x.nil?
        end
      end
    end
  end

  class PropertySelector < Selector
    attr_reader :property
    def initialize(property)
      @property = property
    end

    def evaluate_one(uri, context)
      context.query([uri, property, nil]).lazy.map(&:object)
    end
  end

  class LoosePropertySelector < Selector
    attr_reader :property
    def initialize(property)
      @property = property
    end

    def evaluate_one(uri, context)
      return PropertySelector.new(property).evaluate_one(uri_context) unless defined? RDF::Reasoner

      context.query([uri, nil, nil]).lazy.select do |result|
        result.predicate.entail(:subPropertyOf).include? property
      end.map(&:object)
    end
  end

  class NegatedPropertySelector < Selector
    attr_reader :properties
    def initialize(*properties)
      @properties = properties
    end

    def evaluate_one(uri, context)
      context.query([uri, nil, nil]).lazy.reject do |result|
        properties.include? result.predicate
      end.map(&:object)
    end
  end

  class WildcardSelector < Selector
    def evaluate_one(uri, context)
      context.query([uri, nil, nil]).lazy.map(&:object)
    end
  end

  class ReversePropertySelector < Selector
    attr_reader :property
    def initialize(property)
      @property = property
    end

    def evaluate_one(uri, context)
      context.query([nil, property, uri]).lazy.map(&:subject)
    end
  end

  class RecursivePathSelector < Selector
    attr_reader :property, :repeat
    def initialize(property, repeat)
      @property = property
      @repeat = repeat
    end

    def evaluate(program, uris, context)
      return to_enum(:evaluate, program, uris, context) unless block_given?

      input = enum_wrap(uris)

      (0..repeat.max).each_with_index do |i, idx|
        break if input.none? || (repeat.max == Ldpath::Transform::Infinity && idx > 25) # we're probably lost..
        input = property.evaluate program, input, context

        next unless idx >= repeat.min

        enum_wrap(input).each do |x|
          yield x
        end
      end
    end
  end

  class CompoundSelector < Selector
    attr_reader :left, :right
    def initialize(left, right)
      @left = left
      @right = right
    end
  end

  class PathSelector < CompoundSelector
    def evaluate(program, uris, context, &block)
      return to_enum(:evaluate, program, uris, context) unless block_given?

      output = left.evaluate(program, uris, context)
      right.evaluate(program, output, context, &block)
    end
  end

  class UnionSelector < CompoundSelector
    def evaluate(program, uris, context)
      return to_enum(:evaluate, program, uris, context) unless block_given?

      enum_union(left.evaluate(program, uris, context), right.evaluate(program, uris, context)).each do |x|
        yield x
      end
    end

    private

    def enum_union(left, right)
      return to_enum(:enum_union, left, right) unless block_given?

      enum_wrap(left).each do |e|
        yield e
      end

      enum_wrap(right).each do |e|
        yield e
      end
    end
  end

  class IntersectionSelector < CompoundSelector
    def evaluate(program, uris, context)
      return to_enum(:evaluate, program, uris, context) unless block_given?

      result = left.evaluate(program, uris, context).to_a & right.evaluate(program, uris, context).to_a

      result.each do |x|
        yield x
      end
    end
  end

  class TapSelector < Selector
    attr_reader :identifier, :tap
    def initialize(identifier, tap)
      @identifier = identifier
      @tap = tap
    end

    def evaluate(program, uris, context)
      return to_enum(:evaluate, program, uris, context) unless block_given?

      program.meta[identifier] = tap.evaluate(program, uris, context).map { |x| RDF::Literal.new(x.to_s).canonicalize.object }

      enum_wrap(uris).map do |uri|
        loading program, uri, context
        enum_flatten_one(evaluate_one(uri, context)).each do |x|
          yield x unless x.nil?
        end
      end
    end

    def evaluate_one(uri, _context)
      uri
    end
  end
end
