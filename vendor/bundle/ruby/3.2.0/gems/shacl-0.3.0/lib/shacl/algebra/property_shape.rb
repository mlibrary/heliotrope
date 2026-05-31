require_relative "shape"

module SHACL::Algebra
  ##
  class PropertyShape < Shape
    NAME = :PropertyShape

    # Validates the specified `property` within `graph`, a list of {ValidationResult}.
    #
    # A property conforms the nodes found by evaluating it's `path` all conform.
    #
    # @param [RDF::Term] node focus node
    # @param [Hash{Symbol => Object}] options
    # @return [Array<SHACL::ValidationResult>]
    #   Returns a validation result for each value node.
    def conforms(node, depth: 0, **options)
      return [] if deactivated?
      options = id ? options.merge(shape: id) : options
      options[:severity] = @options[:severity] if @options[:severity]
      options[:severity] ||= RDF::Vocab::SHACL.Violation

      path = @options[:path]
      log_debug(NAME, depth: depth) {SXP::Generator.string({id: id, node: node, path: path}.to_sxp_bin)}
      log_error(NAME, "no path", depth: depth) unless path

      # Turn the `path` attribute into a SPARQL Property Path and evaluate to find related nodes.
      value_nodes = if path.is_a?(RDF::URI)
        graph.query({subject: node, predicate: path}).objects
      elsif path.evaluatable?
        path.execute(graph,
          subject: node,
          object: RDF::Query::Variable.new(:object)).map do
            |soln| soln[:object]
        end.compact.uniq
      else
        log_error(NAME, "Can't handle path", depth: depth) {path.to_sxp}
        []
      end

      # Evaluate against builtins
      builtin_results = @options.map do |k, v|
        self.send("builtin_#{k}".to_sym, v, node, path, value_nodes, depth: depth + 1, **options) if self.respond_to?("builtin_#{k}".to_sym)
      end.flatten.compact

      # Evaluate against operands
      op_results = operands.map do |op|
        if op.is_a?(QualifiedValueConstraintComponent) || op.is_a?(SPARQLConstraintComponent)
          # All value nodes are passed
          op.conforms(node, path: path, value_nodes: value_nodes, depth: depth + 1, **options)
        else
          value_nodes.map do |n|
           res = op.conforms(n, path: path, depth: depth + 1, **options)
           if op.is_a?(NodeShape) && !res.all?(&:conform?)
             # Special case for embedded NodeShape
             not_satisfied(focus: node, path: path,
               value: n,
               message: "node does not conform to #{op.id}",
               resultSeverity: options.fetch(:severity),
               component: RDF::Vocab::SHACL.NodeConstraintComponent,
               **options)
           else
             res
           end
         end
        end
      end.flatten.compact

      builtin_results + op_results
    end

    # The path defined on this property shape
    # @return [RDF::URI, SPARQL::Algebra::Expression]
    def path
      @options[:path]
    end

    # Specifies the condition that each value node is smaller than all the objects of the triples that have the focus node as subject and the value of sh:lessThan as predicate.
    #
    # @example
    #   ex:LessThanExampleShape
    #   	a sh:NodeShape ;
    #   	sh:property [
    #   		sh:path ex:startDate ;
    #   		sh:lessThan ex:endDate ;
    #   	] .
    #
    # @param [RDF::URI] property the property of the focus node whose values must be equal to some value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_lessThan(property, node, path, value_nodes, **options)
      property = property.first if property.is_a?(Array)
      terms = graph.query({subject: node, predicate: property}).objects
      compare(:<, terms, node, path, value_nodes,
              RDF::Vocab::SHACL.LessThanConstraintComponent, **options)
    end

    # Specifies the condition that each value node is smaller than or equal to all the objects of the triples that have the focus node as subject and the value of sh:lessThanOrEquals as predicate.
    #
    # @param [RDF::URI] property the property of the focus node whose values must be equal to some value node.
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_lessThanOrEquals(property, node, path, value_nodes, **options)
      property = property.first if property.is_a?(Array)
      terms = graph.query({subject: node, predicate: property}).objects
      compare(:<=, terms, node, path, value_nodes,
              RDF::Vocab::SHACL.LessThanOrEqualsConstraintComponent, **options)
    end

    ##
    # Builin evaluators
    ##

    # Specifies the maximum number of value nodes.
    #
    # @param [Integer] count
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_maxCount(count, node, path, value_nodes, **options)
      count = count.first if count.is_a?(Array)
      satisfy(focus: node, path: path,
        message: "#{value_nodes.count} <= maxCount #{count}",
        resultSeverity: (options.fetch(:severity) unless value_nodes.count <= count.to_i),
        component: RDF::Vocab::SHACL.MaxCountConstraintComponent,
        **options)
    end

    # Specifies the minimum number of value nodes.
    #
    # @example
    #   ex:MinCountExampleShape
    #   	a sh:PropertyShape ;
    #   	sh:targetNode ex:Alice, ex:Bob ;
    #   	sh:path ex:name ;
    #   	sh:minCount 1 .
    #
    # @param [Integer] count
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_minCount(count, node, path, value_nodes, **options)
      count = count.first if count.is_a?(Array)
      satisfy(focus: node, path: path,
        message: "#{value_nodes.count} >= minCount #{count}",
        resultSeverity: (options.fetch(:severity) unless value_nodes.count >= count.to_i),
        component: RDF::Vocab::SHACL.MinCountConstraintComponent,
        **options)
    end

    # The property `sh:uniqueLang` can be set to `true` to specify that no pair of value nodes may use the same language tag.
    #
    # @param [Boolean] uniq
    # @param [RDF::Term] node the focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Array<RDF::Term>] value_nodes
    # @return [Array<SHACL::ValidationResult>]
    def builtin_uniqueLang(uniq, node, path, value_nodes, **options)
      uniq = uniq.first if uniq.is_a?(Array)
      if !value_nodes.all?(&:literal?)
        not_satisfied(focus: node, path: path,
          message: "not all values are literals",
          resultSeverity: options.fetch(:severity),
          component: RDF::Vocab::SHACL.UniqueLangConstraintComponent,
          **options)
      elsif value_nodes.map(&:language).compact.length != value_nodes.map(&:language).compact.uniq.length
        not_satisfied(focus: node, path: path,
          message: "not all values have unique language tags",
          resultSeverity: options.fetch(:severity),
          component: RDF::Vocab::SHACL.UniqueLangConstraintComponent,
          **options)
      else
        satisfy(focus: node, path: path,
          message: "all literals have unique language tags",
          component: RDF::Vocab::SHACL.UniqueLangConstraintComponent,
          **options)
      end
    end
  end
end
