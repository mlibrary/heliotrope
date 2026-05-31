require 'rdf/n3'

module RDF::N3::Algebra
  #
  # A Notation3 Formula combines a graph with a BGP query.
  class Formula < SPARQL::Algebra::Operator
    include RDF::Term
    include RDF::Enumerable
    include SPARQL::Algebra::Query
    include SPARQL::Algebra::Update
    include RDF::N3::Algebra::Builtin

    ##
    # Query to run against a queryable to determine if the formula matches the queryable.
    #
    # @return [RDF::Query]
    attr_accessor :query

    NAME = :formula

    ##
    # Create a formula from an RDF::Enumerable (such as RDF::N3::Repository)
    #
    # @param [RDF::Enumerable] enumerable
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @return [RDF::N3::Algebra::Formula]
    def self.from_enumerable(enumerable, **options)
      # SPARQL used for SSE and algebra functionality
      require 'sparql' unless defined?(:SPARQL)

      # Create formulae from statement graph_names
      formulae = {}
      enumerable.graph_names.unshift(nil).each do |graph_name|
        formulae[graph_name] = Formula.new(graph_name: graph_name, formulae: formulae, **options)
      end

      # Add patterns to appropiate formula based on graph_name,
      # and replace subject and object bnodes which identify
      # named graphs with those formula
      enumerable.each_statement do |statement|
        # A graph name indicates a formula.
        graph_name = statement.graph_name
        form = formulae[graph_name]

        # Map statement components to formulae, if necessary.
        statement = RDF::Statement.from(statement.to_a.map do |term|
          case term
          when RDF::Node
            term = if formulae[term]
              # Transform blank nodes denoting formulae into those formulae
              formulae[term]
            elsif graph_name
              # If we're in a quoted graph, transform blank nodes into undistinguished existential variables.
              term.to_ndvar(graph_name)
            else
              term
            end
          when RDF::N3::List
            # Transform blank nodes denoting formulae into those formulae
            term = term.transform {|t| t.node? ? formulae.fetch(t, t) : t}

            # If we're in a quoted graph, transform blank node components into existential variables
            if graph_name && term.has_nodes?
              term = term.to_ndvar(graph_name)
            end
          end
          term
        end)

        pattern = statement.variable? ? RDF::Query::Pattern.from(statement) : statement

        # Formulae may be the subject or object of a known operator
        if klass = RDF::N3::Algebra.for(pattern.predicate)
          form.operands << klass.new(pattern.subject,
                                     pattern.object,
                                     formulae: formulae,
                                     parent: form,
                                     predicate: pattern.predicate,
                                     **options)
        else
          pattern.graph_name = nil
          form.operands << pattern
        end
      end

      # Formula is that without a graph name
      this = formulae[nil]

      # If assigned a graph name, add it here
      this.graph_name = options[:graph_name] if options[:graph_name]
      this
    end

    ##
    # Duplicate this formula, recursively, renaming graph names using hash function.
    #
    # @return [RDF::N3::Algebra::Formula]
    def deep_dup
      #new_ops = operands.map(&:dup)
      new_ops = operands.map do |op|
        op.deep_dup
      end
      graph_name = RDF::Node.intern(new_ops.hash)
      log_debug("formula") {"dup: #{self.graph_name} to #{graph_name}"}
      self.class.new(*new_ops, **@options.merge(graph_name: graph_name, formulae: formulae))
    end

    ##
    # Yields solutions from patterns and other operands. Solutions are created by evaluating each pattern and other sub-operand against `queryable`.
    #
    # When executing, blank nodes are turned into non-distinguished existential variables, noted with `$$`. These variables are removed from the returned solutions, as they can't be bound outside of the formula.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param [RDF::Query::Solutions] solutions
    #   initial solutions for chained queries (RDF::Query::Solutions(RDF::Query::Solution.new))
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @return [RDF::Solutions] distinct solutions
    def execute(queryable, solutions: RDF::Query::Solutions(RDF::Query::Solution.new), **options)
      log_info("formula #{graph_name}") {SXP::Generator.string operands.to_sxp_bin}
      log_debug("(formula bindings)") { SXP::Generator.string solutions.to_sxp_bin}

      @query ||= RDF::Query.new(patterns).optimize!
      log_info("(formula query)") { SXP::Generator.string(@query.to_sxp_bin)}

      solutions = if @query.empty?
        solutions
      else
        these_solutions = queryable.query(@query, solutions: solutions, **options)
        if these_solutions.empty?
          # Pattern doesn't match, so there can be no solutions
          log_debug("(formula query solutions)") { SXP::Generator.string([].to_sxp_bin)}
          RDF::Query::Solutions.new
        else
          these_solutions.map! do |solution|
            RDF::Query::Solution.new(solution.to_h.inject({}) do |memo, (name, value)|
              # Replace blank node bindings with lists and formula references with formula, where those blank nodes are associated with lists.
              value = formulae.fetch(value, value) if value.node?
              l = RDF::N3::List.try_list(value, queryable)
              value = l if l.constant?
              memo.merge(name => value)
            end)
          end
          log_debug("(formula query solutions)") { SXP::Generator.string(these_solutions.to_sxp_bin)}
          solutions.merge(these_solutions)
        end
      end

      return solutions if solutions.empty?

      # Reject solutions which include variables as values
      solutions.filter! {|s| s.enum_value.none?(&:variable?)}

      # Use our solutions for sub-ops
      # Join solutions from other operands
      #
      # * Order operands by those having inputs which are constant or bound.
      # * Run built-ins with indeterminant inputs (two-way) until any produces non-empty solutions, and then run remaining built-ins until exhasted or finished.
      # * Re-calculate inputs with bound inputs after each built-in is run.
      log_depth do
        # Iterate over sub_ops using evaluation heuristic
        ops = sub_ops.sort_by {|op| op.rank(solutions)}
        while !ops.empty?
          last_op = nil
          ops.each do |op|
            log_debug("(formula built-in)") {SXP::Generator.string op.to_sxp_bin}
            these_solutions = op.execute(queryable, solutions: solutions)
            # If there are no solutions, try the next one, until we either run out of operations, or we have solutions
            next if these_solutions.empty?
            last_op = op
            solutions = RDF::Query::Solutions(these_solutions)
            break
          end

          # If there is no last_op, there are no solutions.
          unless last_op
            solutions = RDF::Query::Solutions.new
            break
          end

          # Remove op from list, and re-order remaining ops.
          ops = (ops - [last_op]).sort_by {|op| op.rank(solutions)}
        end
      end
      log_info("(formula sub-op solutions)") {SXP::Generator.string solutions.to_sxp_bin}
      solutions
    end

    ##
    # Evaluates the formula using the given variable `bindings` by cloning the formula replacing variables with their bindings recursively.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::N3::List]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae:, **options)
      return self if bindings.empty?
      this = dup
      # Maintain formula relationships
      formulae {|k, v| this.formulae[k] ||= v}

      # Replace operands with bound operands
      this.operands = operands.map do |op|
        op.evaluate(bindings, formulae: formulae, **options)
      end
      this
    end

    ##
    # Returns `true` if `self` is a {RDF::N3::Algebra::Formula}.
    #
    # @return [Boolean]
    def formula?
      true
    end

    ##
    # The formula hash is the hash of it's operands and graph_name.
    #
    # @see RDF::Value#hash
    def hash
      ([graph_name] + operands).hash
    end

    ##
    # Yields each statement from this formula bound to previously determined solutions.
    #
    # @yield  [statement]
    #   each matching statement
    # @yieldparam  [RDF::Statement] statement
    # @yieldreturn [void] ignored
    def each(solutions: RDF::Query::Solutions(RDF::Query::Solution.new), &block)
      log_debug("(formula each)") {SXP::Generator.string([self, solutions].to_sxp_bin)}

      # Yield statements by binding variables
      solutions.each do |solution|
        # Bind blank nodes to the solution when it doesn't contain a solution for an existential variable
        existential_vars.each do |var|
          solution[var.name] ||= RDF::Node.intern(var.name.to_s.sub(/^\$+/, ''))
        end

        log_debug("(formula apply)") {solution.to_sxp}
        # Yield each variable statement which is constant after applying solution
        log_depth do
          n3statements.each do |statement|
            terms = {}
            [:subject, :predicate, :object].each do |part|
              terms[part] = case o = statement.send(part)
              when RDF::Query::Variable
                if solution[o] && solution[o].formula?
                  log_info("(formula from var form)") {solution[o].graph_name.to_sxp}
                  form_statements(solution[o], solution: solution, &block)
                else
                  solution[o] || o
                end
              when RDF::N3::List
                o.variable? ? o.evaluate(solution.bindings, formulae: formulae) : o
              when RDF::N3::Algebra::Formula
                # uses the graph_name of the formula, and yields statements from the formula. No solutions are passed in.
                log_info("(formula from form)") {o.graph_name.to_sxp}
                form_statements(o, solution: solution, &block)
              else
                o
              end
            end

            statement = RDF::Statement.from(terms)
            log_debug("(formula add)") {statement.to_sxp}

            block.call(statement)
          end

          # statements from sub-operands
          sub_ops.each do |op|
            log_debug("(formula sub_op)") {SXP::Generator.string [op, solution].to_sxp_bin}
            op.each(solutions: RDF::Query::Solutions(solution)) do |stmt|
              log_debug("(formula add from sub_op)") {stmt.to_sxp}
              block.call(stmt)
              # Add statements for any term which is a formula
              stmt.to_a.select(&:node?).map {|n| formulae[n]}.compact.each do |ef|
                log_debug("(formula from form)") {ef.graph_name.to_sxp}
                form_statements(ef, solution: solution, &block)              
              end
            end
          end
        end
      end
    end

    ##
    # Yields each pattern which is not a builtin
    #
    # @yield  [pattern]
    #   each matching pattern
    # @yieldparam  [RDF::Query::Pattern] pattern
    # @yieldreturn [void] ignored
    def each_pattern(&block)
      n3statements.each do |statement|
        terms = {}
        [:subject, :predicate, :object].each do |part|
          terms[part] = case o = statement.send(part)
          when RDF::N3::Algebra::Formula
            form_statements(o, solution: RDF::Query::Solution.new(), &block)
          else
            o
          end
        end

        pattern = RDF::Query::Pattern.from(terms)
        block.call(pattern)
      end
    end

    # Graph name associated with this formula
    # @return [RDF::Resource]
    def graph_name; @options[:graph_name]; end

    ##
    # The URI of a formula is its graph name
    # @return [RDF::URI]
    alias_method :to_uri, :graph_name

    # Assign a graph name to this formula
    # @param [RDF::Resource] name
    # @return [RDF::Resource]
    def graph_name=(name)
      formulae[name] = self
      @options[:graph_name] = name
    end

    ##
    # Statements memoizer, from the operands which are statements.
    #
    # Statements may include embedded formulae.
    def n3statements
      # BNodes in statements are existential variables.
      @n3statements ||= begin
        # Operations/Builtins are not statements.
        operands.
          select {|op| op.is_a?(RDF::Statement)}
      end
    end

    ##
    # Patterns memoizer, from the operands which are statements and not builtins.
    #
    # Expands statements containing formulae into their statements.
    def patterns
      # BNodes in statements are existential variables.
      @patterns ||= enum_for(:each_pattern).to_a
    end

    ##
    # Non-statement operands memoizer
    def sub_ops
      # operands that aren't statements, ordered by their graph_name
      @sub_ops ||= operands.reject {|op| op.is_a?(RDF::Statement)}.map do |op|
        # Substitute nodes for existential variables in operator operands
        op.operands.map! do |o|
          case o
          when RDF::N3::List
            # Substitute blank node members with existential variables, recusively.
            graph_name && o.has_nodes? ? o.to_ndvar(graph_name) : o
          when RDF::Node
            graph_name ? o.to_ndvar(graph_name) : o
          else
            o
          end
        end
        op
      end
    end

    ##
    # Return the variables contained within this formula
    # @return [Array<RDF::Query::Variable>]
    def vars
      operands.vars.flatten.compact
    end

    ##
    # Universal vars in this formula and sub-formulae
    # @return [Array<RDF::Query::Variable]
    def universal_vars
      @universals ||= vars.reject(&:existential?).uniq
    end

    ##
    # Existential vars in this formula
    # @return [Array<RDF::Query::Variable]
    def existential_vars
      @existentials ||= vars.select(&:existential?)
    end

    ##
    # Distinguished vars in this formula
    # @return [Array<RDF::Query::Variable]
    def distinguished_vars
      @distinguished ||= vars.vars.select(&:distinguished?)
    end

    ##
    # Undistinguished vars in this formula
    # @return [Array<RDF::Query::Variable]
    def undistinguished_vars
      @undistinguished ||= vars.vars.reject(&:distinguished?)
    end

    def to_s
      to_sxp
    end

    def to_sxp_bin
      [:formula, graph_name].compact +
      operands.map(&:to_sxp_bin)
    end

    def to_base
      inspect
    end

    def inspect
      sprintf("#<%s:%s(%d)>", self.class.name, self.graph_name, self.operands.count)
    end

  private
    # Get statements from a sub-form
    # @return [RDF::Resource] graph name of form
    def form_statements(form, solution:, &block)
      # uses the graph_name of the formula, and yields statements from the formula
      log_depth do
        form.each(solutions: RDF::Query::Solutions(solution)) do |stmt|
          stmt.graph_name ||= form.graph_name
          log_debug("(form statements add)") {stmt.to_sxp}
          block.call(stmt)
        end
      end

      form.graph_name
    end
  end
end
