require 'rdf/n3'

module RDF::N3::Algebra
  ##
  # Behavior for N3 builtin operators
  module Builtin
    include RDF::Enumerable
    include RDF::Util::Logger

    ##
    # Determine ordering for running built-in operator considering if subject or object is varaible and considered an input or an output. Accepts a solution set to determine if variable inputs are bound.
    #
    # @param [RDF::Query::Solutions] solutions
    # @return [Integer] rake for ordering, lower numbers have fewer unbound output variables.
    def rank(solutions)
      vars = input_operand.vars - solutions.variable_names
      # The rank is the remaining unbound variables
      vars.count
    end

    ##
    # Return subject or object operand, or both, depending on which is considered an input.
    #
    # @return [RDF::Term]
    def input_operand
      # By default, return the merger of input and output operands
      RDF::N3::List.new(values: operands)
    end

    ##
    # Evaluates the builtin using the given variable `bindings` by cloning the builtin replacing variables with their bindings recursively.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::N3::Algebra::Builtin]
    #   Returns a new builtin with bound values.
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      args = operands.map { |operand| operand.evaluate(bindings, formulae: formulae, **options) }
      # Replace operands with bound operands
      self.class.new(*args, formulae: formulae, **options)
    end

    ##
    # By default, operators yield themselves and the operands, recursively.
    #
    #  Pass in solutions to have quantifiers resolved to those solutions.
    def each(solutions: RDF::Query::Solutions(), &block)
      log_debug("(#{self.class.const_get(:NAME)} each)")
      log_depth do
        subject, object = operands.map {|op| op.formula? ? op.graph_name : op}
        block.call(RDF::Statement(subject, self.to_uri, object))
        operands.each do |op|
          next unless op.is_a?(Builtin)
          op.each(solutions: solutions) do |st|
            # Maintain formula graph name for formula operands
            st.graph_name ||= op.graph_name if op.formula?
            block.call(st)
          end
        end
      end
    end

    ##
    # The builtin hash is the hash of it's operands and NAME.
    #
    # @see RDF::Value#hash
    def hash
      ([self.class.const_get(:NAME)] + operands).hash
    end

    # The URI of this operator.
    def to_uri
      self.class.const_get(:URI)
    end
  end
end
