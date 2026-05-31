module RDF::N3::Algebra
  ##
  # This is a generic operator where the subject is a literal or binds to a literal and the object is either a constant that equals the evaluation of the subject, or a variable to which the result is bound in a solution
  class ResourceOperator < SPARQL::Algebra::Operator::Binary
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    NAME = :resourceOperator

    ##
    # The operator takes a literal and provides a mechanism for subclasses to operate over (and validate) that argument.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [RDF::Query::Solutions] solutions
    #   solutions for chained queries
    # @return [RDF::Query::Solutions]
    def execute(queryable, solutions:, **options)
      RDF::Query::Solutions(solutions.map do |solution|
        subject = operand(0).evaluate(solution.bindings, formulae: formulae) || operand(0)
        object = operand(1).evaluate(solution.bindings, formulae: formulae) || operand(1)
        subject = formulae.fetch(subject, subject) if subject.node?
        object = formulae.fetch(object, object) if object.node?

        log_info(self.class.const_get(:NAME), "subject") {SXP::Generator.string(subject.to_sxp_bin).strip}
        log_info(self.class.const_get(:NAME), "object") {SXP::Generator.string(object.to_sxp_bin).strip}
        next unless valid?(subject, object)

        lhs = resolve(subject, position: :subject)
        if lhs.nil?
          log_error(self.class.const_get(:NAME), "subject evaluates to null") {subject.inspect}
          next
        end

        rhs = resolve(object, position: :object)
        if rhs.nil?
          log_error(self.class.const_get(:NAME), "object evaluates to null") {object.inspect}
          next
        end

        if object.variable?
          log_debug(self.class.const_get(:NAME), "result") {SXP::Generator.string(lhs.to_sxp_bin).strip}
          solution.merge(object.to_sym => lhs)
        elsif subject.variable?
          log_debug(self.class.const_get(:NAME), "result") {SXP::Generator.string(rhs.to_sxp_bin).strip}
          solution.merge(subject.to_sym => rhs)
        elsif respond_to?(:apply)
          res = apply(lhs, rhs)
          log_debug(self.class.const_get(:NAME), "result") {SXP::Generator.string(res.to_sxp_bin).strip}
          # Return the result applying subject and object
          case res
          when RDF::Literal::TRUE
            solution
          when RDF::Literal::FALSE
            nil
          when RDF::Query::Solution
            solution.merge(res)
          else
            log_error(self.class.const_get(:NAME), "unexpected result type")
            nil
          end
        elsif rhs != lhs
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
    # Returns nil if resource does not validate, given its position
    #
    # @param [RDF::Term] resource
    # @return [RDF::Term]
    def resolve(resource, position: :subject)
      raise NotImplemented
    end

    ##
    # Subclasses may override or supplement validate to perform validation on the list subject
    #
    # @param [RDF::Term] subject
    # @param [RDF::Term] object
    # @return [Boolean]
    def valid?(subject, object)
      case subject
      when RDF::Query::Variable
        object.term?
      when RDF::Term
        object.term? || object.variable?
      else
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
