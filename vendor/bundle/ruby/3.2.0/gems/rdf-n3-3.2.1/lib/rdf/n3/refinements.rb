# Refinements on core RDF class behavior for RDF::N3.
module RDF::N3::Refinements
  # @!parse
  #   # Refinements on RDF::Term
  #   module RDF::Term
  #   ##
  #   # As a term is constant, this returns itself.
  #   #
  #   # @param  [Hash{Symbol => RDF::Term}] bindings
  #   #   a query solution containing zero or more variable bindings
  #   # @param [Hash{Symbol => Object}] options ({})
  #   #   options passed from query
  #   # @return [RDF::Term]
  #   # @see SPARQL::Algebra::Expression.evaluate
  #   def evaluate(bindings, formulae: nil, **options); end
  #   end
  refine ::RDF::Term do
    def evaluate(bindings, formulae:, **options)
      self
    end
  end

  # @!parse
  #   # Refinements on RDF::Node
  #   module RDF::Term
  #     ##
  #     # Blank node may refer to a formula.
  #     #
  #     # @param  [Hash{Symbol => RDF::Term}] bindings
  #     #   a query solution containing zero or more variable bindings
  #     # @param [Hash{Symbol => Object}] options ({})
  #     #   options passed from query
  #     # @return [RDF::Node, RDF::N3::Algebra::Formula]
  #     # @see SPARQL::Algebra::Expression.evaluate
  #     def evaluate(bindings, formulae:, **options); end
  #   end
  refine ::RDF::Node do
    ##
    # @return [RDF::Node, RDF::N3::Algebra::Formula]
    def evaluate(bindings, formulae:, **options)
      node? ? formulae.fetch(self, self) : self
    end
  end

  # @!parse
  #   # Refinements on RDF::Statement
  #   class ::RDF::Statement
  #     # Refines `valid?` to allow literal subjects and BNode predicates.
  #     # @return [Boolean]
  #     def valid?; end
  #
  #     # Refines `invalid?` to allow literal subjects and BNode predicates.
  #     # @return [Boolean]
  #     def invalid?; end
  #
  #     # Refines `validate!` to allow literal subjects and BNode predicates.
  #     # @return [RDF::Value] `self`
  #     # @raise  [ArgumentError] if the value is invalid
  #     def validate!; end
  #
  #     ##
  #     # As a statement is constant, this returns itself.
  #     #
  #     # @param  [Hash{Symbol => RDF::Term}] bindings
  #     #   a query solution containing zero or more variable bindings
  #     # @param [Hash{Symbol => Object}] options ({})
  #     #   options passed from query
  #     # @return [RDF::Statement]
  #     # @see SPARQL::Algebra::Expression.evaluate
  #     def evaluate(bindings, formulae:, **options); end
  #   end
  refine ::RDF::Statement do
    ##
    # Override `valid?` terms as subjects and resources as predicates.
    #
    # @return [Boolean]
    def valid?
      has_subject?    && subject.term? && subject.valid? &&
      has_predicate?  && predicate.term? && predicate.valid? &&
      has_object?     && object.term? && object.valid? &&
      (has_graph?      ? (graph_name.resource? && graph_name.valid?) : true)
    end

    ##
    # @return [Boolean]
    def invalid?
      !valid?
    end

    ##
    # Default validate! implementation, overridden in concrete classes
    # @return [RDF::Value] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      raise ArgumentError, "#{self.inspect} is not valid" if invalid?
      self
    end
    alias_method :validate, :validate!

    ##
    # @return [RDF::Statement]
    def evaluate(bindings, formulae:, **options)
      self
    end
  end

  # @!parse
  #   # Refinements on RDF::Query::Pattern
  #   class ::RDF::Query::Pattern
  #     # Refines `#valid?` to allow literal subjects and BNode predicates.
  #     # @return [Boolean]
  #     def valid?; end
  #
  #     ##
  #     # Evaluates the pattern using the given variable `bindings` by cloning the pattern replacing variables with their bindings recursively. If the resulting pattern is constant, it is cast as a statement.
  #     #
  #     # @param  [Hash{Symbol => RDF::Term}] bindings
  #     #   a query solution containing zero or more variable bindings
  #     # @param [Hash{Symbol => Object}] options ({})
  #     #   options passed from query
  #     # @return [RDF::Statement, RDF::N3::Algebra::Formula]
  #     # @see SPARQL::Algebra::Expression.evaluate
  #     def evaluate(bindings, formulae:, **options); end
  #   end
  refine ::RDF::Query::Pattern do
    ##
    # Is this pattern composed only of valid components?
    #
    # @return [Boolean] `true` or `false`
    def valid?
      (has_subject?   ? (subject.term? || subject.variable?) && subject.valid? : true) && 
      (has_predicate? ? (predicate.term? || predicate.variable?) && predicate.valid? : true) &&
      (has_object?    ? (object.term? || object.variable?) && object.valid? : true) &&
      (has_graph?     ? (graph_name.resource? || graph_name.variable?) && graph_name.valid? : true)
    rescue NoMethodError
      false
    end

    # @return [RDF::Statement, RDF::N3::Algebra::Formula]
    def evaluate(bindings, formulae:, **options)
      elements = self.to_quad.map do |term|
        term.evaluate(bindings, formulae: formulae, **options)
      end.compact.map do |term|
        term.node? ? formulae.fetch(term, term) : term
      end

      self.class.from(elements)
    end
  end

  # @!parse
  #   # Refinements on RDF::Query::Variable
  #   class RDF::Query::Variable
  #     ##
  #     # If variable is bound, replace with the bound value, otherwise, returns itself
  #     #
  #     # @param  [Hash{Symbol => RDF::Term}] bindings
  #     #   a query solution containing zero or more variable bindings
  #     # @param [Hash{Symbol => Object}] options ({})
  #     #   options passed from query
  #     # @return [RDF::Term]
  #     # @see SPARQL::Algebra::Expression.evaluate
  #     def evaluate(bindings, formulae:, **options); end
  #   end
  refine ::RDF::Query::Variable do
    ##
    # @return [RDF::Term]
    def evaluate(bindings, formulae:, **options)
      value = bindings.has_key?(name) ? bindings[name] : self
      value.node? ? formulae.fetch(value, value) : value
    end
  end

  refine ::RDF::Graph do
    # Allow a graph to be treated as a term in a statement.

    ##
    # @overload term?
    #   Returns `true` if `self` is a {RDF::Term}.
    #
    #   @return [Boolean]
    # @overload term?(name)
    #   Returns `true` if `self` contains the given RDF subject term.
    #
    #   @param  [RDF::Resource] value
    #   @return [Boolean]
    def term?(*args)
      case args.length
      when 0 then true
      when 1 then false
      else raise ArgumentError("wrong number of arguments (given #{args.length}, expected 0 or 1)")
      end
    end

    ##
    # Returns itself.
    #
    # @return [RDF::Value]
    def to_term
      statements.map(&:terms)
      self
    end
  end
end
