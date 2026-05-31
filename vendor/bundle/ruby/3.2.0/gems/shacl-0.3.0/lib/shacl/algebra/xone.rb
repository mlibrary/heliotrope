module SHACL::Algebra
  ##
  class XoneConstraintComponent < ConstraintComponent
    NAME = :xone

    ##
    # Specifies the condition that each value node conforms to exactly one of the provided shapes.
    #
    # @example
    #   ex:XoneConstraintExampleShape
    #   	a sh:NodeShape ;
    #   	sh:targetClass ex:Person ;
    #   	sh:xone (
    #   		[
    #   			sh:property [
    #   				sh:path ex:fullName ;
    #   				sh:minCount 1 ;
    #   			]
    #   		]
    #   		[
    #   			sh:property [
    #   				sh:path ex:firstName ;
    #   				sh:minCount 1 ;
    #   			] ;
    #   			sh:property [
    #   				sh:path ex:lastName ;
    #   				sh:minCount 1 ;
    #   			]
    #   		]
    #   	) .
    #
    # @param [RDF::Term] node focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property   
    # @param [Hash{Symbol => Object}] options
    # @return [Array<SHACL::ValidationResult>]
    def conforms(node, path: nil, depth: 0, **options)
      log_debug(NAME, depth: depth) {SXP::Generator.string({node: node}.to_sxp_bin)}
      num_conform = operands.inject(0) do |memo, op|
        results = op.conforms(node, depth: depth + 1, **options)
        memo += (results.flatten.all?(&:conform?) ? 1 : 0)
      end
      case num_conform
      when 0
        not_satisfied(focus: node, path: path,
          value: node,
          message: "node does not conform to any shape",
          resultSeverity: options.fetch(:severity),
          component: RDF::Vocab::SHACL.XoneConstraintComponent,
          depth: depth, **options)
      when 1
        satisfy(focus: node, path: path,
          value: node,
          message: "node conforms to a single shape",
          component: RDF::Vocab::SHACL.XoneConstraintComponent,
          depth: depth, **options)
      else
        not_satisfied(focus: node, path: path,
          value: node,
          message: "node conforms to #{num_conform} shapes",
          resultSeverity: options.fetch(:severity),
          component: RDF::Vocab::SHACL.XoneConstraintComponent,
          depth: depth, **options)
      end
    end
  end
end
