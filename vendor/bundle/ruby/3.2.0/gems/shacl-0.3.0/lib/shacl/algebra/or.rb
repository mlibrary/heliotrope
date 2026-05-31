module SHACL::Algebra
  ##
  class OrConstraintComponent < ConstraintComponent
    NAME = :or

    ##
    # Specifies the condition that each value node conforms to at least one of the provided shapes. This is comparable to disjunction and the logical "or" operator.
    #
    # @example
    #   ex:OrConstraintExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetNode ex:Bob ;
    #   	sh:or (
    #   		[
    #   			sh:path ex:firstName ;
    #   			sh:minCount 1 ;
    #   		]
    #   		[
    #   			sh:path ex:givenName ;
    #   			sh:minCount 1 ;
    #   		]
    #   	) .
    #
    # @param [RDF::Term] node focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Hash{Symbol => Object}] options
    # @return [Array<SHACL::ValidationResult>]
    def conforms(node, path: nil, depth: 0, **options)
      log_debug(NAME, depth: depth) {SXP::Generator.string({node: node}.to_sxp_bin)}
      operands.each do |op|
        results = op.conforms(node, depth: depth + 1, **options)
        next unless results.all?(&:conform?)
        return satisfy(focus: node, path: path,
          value: node,
          message: "node conforms to some shape",
          component: RDF::Vocab::SHACL.OrConstraintComponent,
          depth: depth, **options)
      end
      return not_satisfied(focus: node, path: path,
        value: node,
        message: "node does not conform to any shape",
        resultSeverity: options.fetch(:severity),
        component: RDF::Vocab::SHACL.OrConstraintComponent,
        depth: depth, **options)
    end
  end
end
