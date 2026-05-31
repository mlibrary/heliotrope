module ShEx::Algebra
  ##
  class SemAct < Operator
    NAME = :semact

    ##
    # Creates an operator instance from a parsed ShExJ representation
    # @param (see Operator#from_shexj)
    # @return [Operator]
    def self.from_shexj(operator, **options)
      raise ArgumentError unless operator.is_a?(Hash) && operator['type'] == "SemAct"
      raise ArgumentError, "missing name in #{operator.inspect}" unless operator.has_key?('name')
      code = operator.delete('code')
      operator['code'] = code if code # Reorders operands appropriately
      super
    end

    ##
    # Called on entry
    #
    # @overload enter(code, arcs_in, arcs_out, logging)
    #   @param [String] code
    #   @param [Array<RDF::Statement>] arcs_in available statements to be matched having `focus` as an object
    #   @param [Array<RDF::Statement>] arcs_out available statements to be matched having `focus` as a subject
    #   @param [Integer] depth for logging
    #   @param [Hash{Symbol => Object}] options
    #     Other, operand-specific options
    #   @return [Boolean] Returning `false` results in {ShEx::NotSatisfied} exception
    def enter(**options)
      if implementation = schema.extensions[operands.first.to_s]
        implementation.enter(code: operands[0], expression: parent, **options)
      end
    end

    #
    # The evaluation semActsSatisfied on a list of SemActs returns success or failure. The evaluation of an individual SemAct is implementation-dependent.
    #
    # In addition to standard arguments `satsisfies` arguments, the current `matched` and `unmatched` statements may be passed. Additionally, all sub-classes of `Operator` have available `parent`, and `schema` accessors, which allows access to the operands of the parent, for example.
    #
    # @param [Object] focus (ignored)
    # @param [Array<RDF::Statement>] matched matched statements
    # @param [Array<RDF::Statement>] unmatched unmatched statements
    # @return [Boolean] `true` if satisfied, `false` if it does not apply
    # @raise [ShEx::NotSatisfied] if not satisfied
    def satisfies?(focus, matched: [], unmatched: [], depth: 0)
      if implementation = schema.extensions[operands.first.to_s]
        if matched.empty?
          implementation.visit(code: operands[1],
                         expression: parent,
                              depth: depth) ||
            not_satisfied("SemAct failed", unmatched: unmatched)
        end
        matched.all? do |statement|
          implementation.visit(code: operands[1],
                            matched: statement,
                         expression: parent,
                              depth: depth)
        end || not_satisfied("SemAct failed", matched: matched, unmatched: unmatched)
      else
        status("unknown SemAct name #{operands.first}", depth: depth) {"expression: #{self.to_sxp}"}
        false
      end
    end

    ##
    # Called on exit from containing {ShEx::TripleExpression}
    #
    # @param [String] code
    # @param [Array<RDF::Statement>] matched statements matched by this expression
    # @param [Array<RDF::Statement>] unmatched statements considered, but not matched by this expression
    # @param [Integer] depth for logging
    # @param [Hash{Symbol => Object}] options
    #   Other, operand-specific options
    # @return [void]
    def exit(code: nil, matched: [], unmatched: [], depth: 0, **options)
      if implementation = schema.extensions[operands.first.to_s]
        implementation.exit(code: operands[1],
                         matched: matched,
                       unmatched: unmatched,
                     expresssion: parent,
                           depth: depth)
      end
    end

    # Does This operator is SemAct
    def semact?; true; end
  end
end
