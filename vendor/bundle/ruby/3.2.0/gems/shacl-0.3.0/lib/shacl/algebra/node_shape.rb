require_relative "shape"

module SHACL::Algebra
  ##
  class NodeShape < SHACL::Algebra::Shape
    NAME = :NodeShape

    # Validates the specified `node` within `graph`, a list of {ValidationResult}.
    #
    # A node conforms if it is not deactivated and all of its operands conform.
    #
    # @param [RDF::Term] node focus node
    # @param [Hash{Symbol => Object}] options
    # @return [Array<SHACL::ValidationResult>]
    #   Returns one or more validation results for each operand.
    def conforms(node, depth: 0, **options)
      return [] if deactivated?
      options = id ? options.merge(shape: id) : options
      options[:severity] = @options[:severity] if @options[:severity]
      options[:severity] ||= RDF::Vocab::SHACL.Violation
      log_debug(NAME, depth: depth) {SXP::Generator.string({id: id, node: node}.to_sxp_bin)}

      # Evaluate against builtins
      builtin_results = @options.map do |k, v|
        self.send("builtin_#{k}".to_sym, v, node, nil, [node],
                  depth: depth + 1,
                  **options) if self.respond_to?("builtin_#{k}".to_sym)
      end.flatten.compact

      # Handle closed shapes
      # FIXME: this only considers URI paths, not property paths
      closed_results = []
      if @options[:closed]
        shape_paths = operands.select {|o| o.is_a?(PropertyShape)}.map(&:path)
        shape_properties = shape_paths.select {|p| p.is_a?(RDF::URI)}
        shape_properties += Array(@options[:ignoredProperties])

        closed_results = graph.query({subject: node}).map do |statement|
          next if shape_properties.include?(statement.predicate)
          not_satisfied(focus: node,
            value: statement.object,
            path: statement.predicate,
            message: "closed node has extra property",
            resultSeverity: options[:severity],
            component: RDF::Vocab::SHACL.ClosedConstraintComponent,
            **options)
        end.compact
      elsif @options[:ignoredProperties]
        raise SHACL::Error, "shape has ignoredProperties without being closed"
      end

      # Evaluate against operands
      op_results = operands.map do |op|
        res = op.conforms(node,
          focus: options.fetch(:focusNode, node),
          depth: depth + 1,
          **options)
        if op.is_a?(NodeShape) && !res.all?(&:conform?)
          # Special case for embedded NodeShape
          not_satisfied(focus: node,
            value: node,
            message: "node does not conform to #{op.id}",
            resultSeverity: options[:severity],
            component: RDF::Vocab::SHACL.NodeConstraintComponent,
            **options)
        else
          res
        end
      end.flatten.compact

      builtin_results + closed_results + op_results
    end
  end
end
