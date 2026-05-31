module Ldpath
  class Result
    include Ldpath::Functions
    attr_reader :program, :uri, :cache, :loaded

    def initialize(program, uri, cache: RDF::Util::Cache.new, context: nil, limit_to_context: false)
      @program = program
      @uri = uri
      @cache = cache
      @loaded = {}
      @context = context
      @limit_to_context = limit_to_context
    end

    def loading(uri, context)
      return unless uri.to_s =~ /^http/
      return if loaded[uri.to_s]

      context << load_graph(uri.to_s) unless limit_to_context?
      context
    end

    def load_graph(uri)
      cache[uri] ||= begin
        program.load(uri).tap { loaded[uri] = true }
      end
    end

    def [](key)
      evaluate(mappings.find { |x| x.name == key })
    end

    def to_hash
      h = mappings.each_with_object({}) do |mapping, hash|
        hash[mapping.name] = evaluate(mapping).to_a
      end

      h.merge(meta)
    end

    def func_call(fname, uri, context, *arguments)
      raise "No such function: #{fname}" unless function_method? fname

      public_send(fname, uri, context, *arguments)
    end

    def context
      @context ||= load_graph(uri.to_s)
    end

    def prefixes
      program.prefixes
    end

    def meta
      @meta ||= {}
    end

    private

    def evaluate(mapping)
      mapping.evaluate(self, uri, context)
    end

    def function_method?(function)
      Functions.public_instance_methods(false).include? function.to_sym
    end

    def mappings
      program.mappings
    end

    def limit_to_context?
      @limit_to_context
    end
  end
end
