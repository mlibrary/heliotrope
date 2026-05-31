module ShEx::Algebra
  ##
  class Schema < Operator
    NAME = :schema

    # Graph to validate
    # @return [RDF::Queryable]
    attr_accessor :graph

    # Map of nodes to shapes
    # @return [Hash{RDF::Resource => RDF::Resource}]
    attr_reader :map

    # Map of Semantic Action instances
    # @return [Hash{String => ShEx::Extension}]
    attr_reader :extensions

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "Schema"
      super
    end

    # (see Operator#initialize)
    def initialize(*operands, **options)
      super
      schema = self
      each_descendant do |op|
        # Set schema everywhere
        op.schema = self
      end
    end

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param [RDF::Queryable] graph
    # @param [Hash{RDF::Term => <RDF::Resource>}, Array<Array(RDF::Term, RDF::Resource)>] map
    #   A set of (`term`, `resource`) pairs where `term` is a node within `graph`, and `resource` identifies a shape
    # @param [Array<RDF::Term>] focus ([])
    # 	One or more nodes within `graph` for which to run the start expression.
    # @param [Array<Schema, String>] shapeExterns ([])
    #   One or more schemas, or paths to ShEx schema resources used for finding external shapes.
    # @return [Hash{RDF::Term => Array<ShapeResult>}] Returns _ShapeResults_, a hash of graph nodes to the results of their associated shapes
    # @param [Hash{Symbol => Object}] options
    # @option options [String] :base_uri (for resolving focus)
    # @raise [ShEx::NotSatisfied] along with individual shape results
    def execute(graph, map, focus: [], shapeExterns: [], depth: 0, **options)
      @graph, @shapes_entered, results = graph, {}, {}
      @external_schemas = shapeExterns
      @extensions = {}
      focus = Array(focus).map {|f| value(f, **options)}

      logger = options[:logger] || @options[:logger]
      each_descendant do |op|
        # Set logging everywhere
        op.logger = logger
      end

      # Initialize Extensions
      each_descendant do |op|
        next unless op.is_a?(SemAct)
        name = op.operands.first.to_s
        if ext_class = ShEx::Extension.find(name)
          @extensions[name] ||= ext_class.new(schema: self, depth: depth, **options)
        end
      end

      # If `n` is a Blank Node, we won't find it through normal matching, find an equivalent node in the graph having the same id
      @map = case map
      when Hash
        map.inject({}) do |memo, (node, shapes)|
          gnode = graph.enum_term.detect {|t| t.node? && t.id == node.id} if node.is_a?(RDF::Node)
          node = gnode if gnode
          memo.merge(node => Array(shapes))
        end
      when Array
        map.inject({}) do |memo, (node, shape)|
          gnode = graph.enum_term.detect {|t| t.node? && t.id == node.id} if node.is_a?(RDF::Node)
          node = gnode if gnode
          (memo[node] ||= []).concat(Array(shape))
          memo
        end
      when nil then {}
      else
        structure_error "Unrecognized shape map: #{map.inspect}"
      end

      # First, evaluate semantic acts
      semantic_actions.all? do |op|
        op.satisfies?([], depth: depth + 1)
      end

      # Next run any start expression
      if !focus.empty?
        if start
          focus.each do |node|
            node = graph.enum_term.detect {|t| t.node? && t.id == node.id} if node.is_a?(RDF::Node)
            sr = ShapeResult.new(RDF::URI("http://www.w3.org/ns/shex#Start"))
            (results[node] ||= []) << sr
            begin
              sr.expression = start.satisfies?(node, depth: depth + 1)
              sr.result = true
            rescue ShEx::NotSatisfied => e
              sr.expression = e.expression
              sr.result = false
            end
          end
        else
          structure_error "Focus nodes with no start"
        end
      end

      # Match against all shapes associated with the ids for focus
      @map.each do |node, shapes|
        results[node] ||= []
        shapes.each do |id|
          enter_shape(id, node) do |shape|
            sr = ShapeResult.new(id)
            results[node] << sr
            begin
              sr.expression = shape.satisfies?(node, depth: depth + 1)
              sr.result = true
            rescue ShEx::NotSatisfied => e
              sr.expression = e.expression
              sr.result = false
            end
          end
        end
      end

      if results.values.flatten.all? {|sr| sr.result}
        status "schema satisfied", depth: depth
        results
      else
        raise ShEx::NotSatisfied.new("Graph does not conform to schema", expression: results)
      end
    ensure
      # Close Semantic Action extensions
      @extensions.values.each {|ext| ext.close(schema: self, depth: depth, **options)}
    end

    ##
    # Match on schema. Finds appropriate shape for node, and matches that shape.
    #
    # @param (see ShEx::Algebra::Schema#execute)
    # @param [Hash{Symbol => Object}] options
    # @option options [String] :base_uri
    # @return [Boolean]
    def satisfies?(graph, map, **options)
      execute(graph, map, **options)
    rescue ShEx::NotSatisfied
      false
    end

    ##
    # Shapes as a hash
    # @return [Array<Operator>]
    def shapes
      @shapes ||= begin
        shapes = Array(operands.detect {|op| op.is_a?(Array) && op.first == :shapes})
        Array(shapes[1..-1])
      end
    end

    ##
    # Indicate that a shape has been entered with a specific focus node. Any future attempt to enter the same shape with the same node raises an exception.
    # @param [RDF::Resource] id
    # @param [RDF::Resource] node
    # @yield :shape
    # @yieldparam [ShapeExpression] shape, or `nil` if shape already entered
    # @return (see ShapeExpression#satisfies?)
    # @raise (see ShapeExpression#satisfies?)
    def enter_shape(id, node, &block)
      shape = shapes.detect {|s| s.id == id}
      structure_error("No shape found for #{id}") unless shape
      @shapes_entered[id] ||= {}
      if @shapes_entered[id][node]
        block.call(false)
      else
        @shapes_entered[id][node] = self
        begin
          block.call(shape)
        ensure
          @shapes_entered[id].delete(node)
        end
      end
    end
    
    ##
    # Externally loaded schemas, lazily evaluated
    # @return [Array<Schema>]
    def external_schemas
      @external_schemas = Array(@external_schemas).map do |extern|
        schema = case extern
        when Schema then extern
        else
          status "Load extern #{extern}"
          ShEx.open(extern, logger: options[:logger])
        end
        schema.graph = graph
        schema
      end
    end

    ##
    # Start action, if any
    def start
      @start ||= operands.detect {|op| op.is_a?(Start)}
    end

    ##
    # Validate shapes, in addition to other operands
    # @return [Operator] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      shapes.each do |op|
        op.validate! if op.respond_to?(:validate!)
        if op.is_a?(RDF::Resource)
          ref = find(op)
          structure_error("Missing reference: #{op}") if ref.nil?
        end
      end
      super
    end
  end

  # A shape result
  class ShapeResult
    # The label of the shape within the schema, or a URI indicating a start shape
    # @return [RDF::Resource]
    attr_reader :shape

    # Does the node conform to the shape
    # @return [Boolean]
    attr_accessor :result

    # The annotated {Operator} indicating processing results
    # @return [ShEx::Algebra::Operator]
    attr_accessor :expression

    # Holds the result of processing a shape
    # @param [RDF::Resource] shape
    # @return [ShapeResult]
    def initialize(shape)
      @shape = shape
    end

    # The SXP of {#expression}
    # @return [String]
    def reason
      SXP::Generator.string(expression.to_sxp_bin)
    end

    ##
    # Returns the binary S-Expression (SXP) representation of this result.
    #
    # @return [Array]
    # @see    https://en.wikipedia.org/wiki/S-expression
    def to_sxp_bin
      [:ShapeResult, shape, result, expression].map(&:to_sxp_bin)
    end
  end
end
