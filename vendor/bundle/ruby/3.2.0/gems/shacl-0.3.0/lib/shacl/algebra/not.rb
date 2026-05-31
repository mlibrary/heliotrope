module SHACL::Algebra
  ##
  class NotConstraintComponent < ConstraintComponent
    NAME = :not

    ##
    # Specifies the condition that each value node cannot conform to a given shape. This is comparable to negation and the logical "not" operator.
    #
    # @param [RDF::Term] node focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Hash{Symbol => Object}] options
    # @return [Array<SHACL::ValidationResult>]
    def conforms(node, path: nil, depth: 0, **options)
      log_debug(NAME, depth: depth) {SXP::Generator.string({node: node}.to_sxp_bin)}
      operands.each do |op|
        results = op.conforms(node, depth: depth + 1, **options)
        if results.any?(&:conform?)
          return not_satisfied(focus: node, path: path,
            message: "node does not conform to some shape",
            resultSeverity: options.fetch(:severity),
            component: RDF::Vocab::SHACL.NotConstraintComponent,
            value: node, depth: depth, **options)
        end
      end
      satisfy(focus: node, path: path,
        message: "node conforms to all shapes",
        component: RDF::Vocab::SHACL.NotConstraintComponent,
        value: node, depth: depth, **options)
    end
  end
end
