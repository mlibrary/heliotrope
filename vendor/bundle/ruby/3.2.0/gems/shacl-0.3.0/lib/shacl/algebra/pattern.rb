module SHACL::Algebra
  ##
  class PatternConstraintComponent < ConstraintComponent
    NAME = :pattern

    ##
    # Specifies a regular expression that each value node matches to satisfy the condition.
    #
    # @example
    #   ex:PatternExampleShape
    #     a sh:NodeShape ;
    #     sh:targetNode ex:Bob, ex:Alice, ex:Carol ;
    #     sh:property [
    #       sh:path ex:bCode ;
    #       sh:pattern "^B" ;    # starts with 'B'
    #       sh:flags "i" ;       # Ignore case
    #     ] .
    #
    # @param [RDF::Term] node focus node
    # @param [RDF::URI, SPARQL::Algebra::Expression] path (nil) the property path from the focus node to the value nodes.
    # @param [Hash{Symbol => Object}] options
    # @return [Array<SHACL::ValidationResult>]
    def conforms(node, path: nil, depth: 0, **options)
      log_debug(NAME, depth: depth) {SXP::Generator.string({node: node}.to_sxp_bin)}
      pattern = Array(operands.first).first
      flags = operands.last.last if operands.last.is_a?(Array) && operands.last.first == :flags
      flags = flags.to_s
      regex_opts = 0
      regex_opts |= Regexp::MULTILINE  if flags.include?(?m)
      regex_opts |= Regexp::IGNORECASE if flags.include?(?i)
      regex_opts |= Regexp::EXTENDED   if flags.include?(?x)
      pat = Regexp.new(pattern, regex_opts)

      compares = !node.node? && pat.match?(node.to_s)
      satisfy(focus: node, path: path,
        value: node,
        message: "is#{' not' unless compares} a match #{pat.inspect}",
        resultSeverity: (options.fetch(:severity) unless compares),
        component: RDF::Vocab::SHACL.PatternConstraintComponent,
        **options)
    end
  end
end
