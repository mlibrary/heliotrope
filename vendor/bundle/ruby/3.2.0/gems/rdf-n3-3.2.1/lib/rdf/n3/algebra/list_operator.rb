module RDF::N3::Algebra
  ##
  # This is a generic operator where the subject is a list or binds to a list and the object is either a constant that equals the evaluation of the subject, or a variable to which the result is bound in a solution
  class ListOperator < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    NAME = :listOperator

    ##
    # The operator takes a list and provides a mechanism for subclasses to operate over (and validate) that list argument.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [RDF::Query::Solutions] solutions
    #   solutions for chained queries
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      RDF::Query::Solutions(solutions.map do |solution|
        # Might be a variable or node evaluating to a list in queryable, or might be a list with variables
        subject = operand(0).evaluate(solution.bindings, formulae: formulae)
        next unless subject
        # If it evaluated to a BNode, re-expand as a list
        subject = RDF::N3::List.try_list(subject, queryable).evaluate(solution.bindings, formulae: formulae)
        object = operand(1).evaluate(solution.bindings, formulae: formulae) || operand(1)
        object = formulae.fetch(object, object) if object.node?

        log_info(self.class.const_get(:NAME), "subject") {SXP::Generator.string(subject.to_sxp_bin).strip}
        log_info(self.class.const_get(:NAME), "object") {SXP::Generator.string(object.to_sxp_bin).strip}
        next unless validate(subject)

        lhs = resolve(subject)
        if lhs.nil?
          log_error(self.class.const_get(:NAME), "subject evaluates to null") {subject.inspect}
          next
        end

        if object.variable?
          log_debug(self.class.const_get(:NAME), "result") {SXP::Generator.string(lhs.to_sxp_bin).strip}
          solution.merge(object.to_sym => lhs)
        elsif object != lhs
          log_debug(self.class.const_get(:NAME), "result: false")
          nil
        else
          log_debug(self.class.const_get(:NAME), "result: true")
          solution
        end
      end.compact.uniq)
    end

    ##
    # Input is generically the subject
    #
    # @return [RDF::Term]
    def input_operand
      operand(0)
    end

    ##
    # Subclasses implement `resolve`.
    #
    # @param [RDF::N3::List] list
    # @return [RDF::Term]
    def resolve(list)
      raise NotImplemented
    end

    ##
    # Subclasses may override or supplement validate to perform validation on the list subject
    #
    # @param [RDF::N3::List] list
    # @return [Boolean]
    def validate(list)
      if list.list? && list.valid?
        true
      else
        log_error(NAME) {"operand is not a list: #{list.to_sxp}"}
        false
      end
    end

    ##
    # Returns a literal for the numeric argument.
    def as_literal(object)
      case object
      when Float
        literal = RDF::Literal(object, canonicalize: true)
        literal.instance_variable_set(:@string, literal.to_s.downcase)
        literal
      else
        RDF::Literal(object, canonicalize: true)
      end
    end
  end
end
