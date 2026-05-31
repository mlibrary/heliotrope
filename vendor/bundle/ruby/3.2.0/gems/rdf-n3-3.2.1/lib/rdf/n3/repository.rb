module RDF::N3
  ##
  # Sub-class of RDF::Repository which allows for native lists in different positions.
  class Repository < RDF::Repository
    DEFAULT_GRAPH = false

    ##
    # Initializes this repository instance.
    #
    # @param [URI, #to_s]    uri (nil)
    # @param [String, #to_s] title (nil)
    # @param [Hash{Symbol => Object}] options
    # @option options [Boolean]   :with_graph_name (true)
    #   Indicates that the repository supports named graphs, otherwise,
    #   only the default graph is supported.
    # @option options [Boolean]   :with_validity (true)
    #   Indicates that the repository supports named validation.
    # @option options [Boolean]   :transaction_class (DEFAULT_TX_CLASS)
    #   Specifies the RDF::Transaction implementation to use in this Repository.
    # @yield  [repository]
    # @yieldparam [Repository] repository
    def initialize(uri: nil, title: nil, **options, &block)
      @data = options.delete(:data) || {}
      super do
        if block_given?
          case block.arity
            when 1 then block.call(self)
            else instance_eval(&block)
          end
        end
      end
    end

    ##
    # Returns `true` if this respository supports the given `feature`.
    #
    # This repository supports list_terms.
    def supports?(feature)
      case feature.to_sym
      when :list_terms       then true
      when :rdfstar          then true
      when :snapshots        then false
      else super
      end
    end

    ##
    # Creates a query from the statements in this repository, turning blank nodes into non-distinguished variables. This can be used to determine if this repository is logically a subset of another repository.
    #
    # @return [RDF::Query]
    def to_query
      RDF::Query.new do |query|
        each do |statement|
          query.pattern RDF::Query::Pattern.from(statement, ndvars: true)
        end
      end
    end

    ##
    # @private
    # @see RDF::Countable#count
    def count
      count = 0
      @data.each do |_, ss|
        ss.each do |_, ps|
          ps.each { |_, os| count += os.size }
        end
      end
      count
    end
    
    ##
    # @private
    # @see RDF::Enumerable#has_graph?      
    def has_graph?(graph)
      @data.has_key?(graph)
    end

    ##
    # @private
    # @see RDF::Enumerable#each_graph
    def graph_names(options = nil, &block)        
      @data.keys.reject { |g| g == DEFAULT_GRAPH }.to_a
    end

    ##
    # @private
    # @see RDF::Enumerable#each_graph
    def each_graph(&block)
      if block_given?
        @data.each_key do |gn|
          yield RDF::Graph.new(graph_name: (gn == DEFAULT_GRAPH ? nil : gn), data: self)
        end
      end
      enum_graph
    end

    ##
    # @private
    # @see RDF::Enumerable#has_statement?
    def has_statement?(statement)
      has_statement_in?(@data, statement)
    end

    ##
    # @private
    # @see RDF::Enumerable#each_statement
    def each_statement(&block)
      if block_given?
        @data.each do |g, ss|
          ss.each do |s, ps|
            ps.each do |p, os|
              os.each do |o, object_options|
                yield RDF::Statement.new(s, p, o, object_options.merge(graph_name: g.equal?(DEFAULT_GRAPH) ? nil : g))
              end
            end
          end
        end
      end
      enum_statement
    end
    alias_method :each, :each_statement

    ##
    # Projects statements with lists expanded to first/rest chains
    #
    # @yield [RDF::Statement]
    def each_expanded_statement(&block)
      if block_given?
        each_statement do |st|
          if st.subject.list?
            st.subject.each_statement(&block)
            st.subject = st.subject.subject
          end
          if st.object.list?
            st.object.each_statement(&block)
            st.object = st.object.subject
          end
          block.call(st)
        end
      end
      enum_for(:each_expanded_statement) unless block_given?
    end

    ##
    # Returns the expanded statements for this repository
    #
    # @return [Array<RDF::Statement>]
    def expanded_statements
      each_expanded_statement.to_a
    end

    ##
    # @see Mutable#apply_changeset
    def apply_changeset(changeset)
      data = @data
      changeset.deletes.each do |del|
        if del.constant?
          data = delete_from(data, del)
        else
          # we need this condition to handle wildcard statements
          query_pattern(del) { |stmt| data = delete_from(data, stmt) }
        end
      end
      changeset.inserts.each { |ins| data = insert_to(data, ins) }
      @data = data
    end

    ##
    # @see RDF::Dataset#isolation_level
    def isolation_level
      :serializable
    end

    protected

    ##
    # Match elements with `eql?`, not `==`
    #
    # `graph_name` of `false` matches default graph. Unbound variable matches
    # non-false graph name.
    #
    # Matches terms which are native lists.
    #
    # @private
    # @see RDF::Queryable#query_pattern
    def query_pattern(pattern, **options, &block)
      if block_given?
        graph_name  = pattern.graph_name
        subject     = pattern.subject
        predicate   = pattern.predicate
        object      = pattern.object

        cs = @data.has_key?(graph_name) ? { graph_name => @data[graph_name] } : @data

        cs.each do |c, ss|
          next unless graph_name.nil? ||
                      graph_name == DEFAULT_GRAPH && !c ||
                      graph_name.eql?(c)

          ss = if subject.nil? || subject.is_a?(RDF::Query::Variable)
            ss
          elsif subject.is_a?(RDF::N3::List)
            # Match subjects which are eql lists
            ss.keys.select {|s| s.list? && subject.eql?(s)}.inject({}) do |memo, li|
              memo.merge(li => ss[li])
            end
          elsif subject.is_a?(RDF::Query::Pattern)
            # Match subjects which are statements matching this pattern
            ss.keys.select {|s| s.statement? && subject.eql?(s)}.inject({}) do |memo, st|
              memo.merge(st => ss[st])
            end
          elsif ss.has_key?(subject)
            { subject => ss[subject] }
          else
            []
          end
          ss.each do |s, ps|
            ps = if predicate.nil? || predicate.is_a?(RDF::Query::Variable)
              ps
            elsif predicate.is_a?(RDF::N3::List)
              # Match predicates which are eql lists
              ps.keys.select {|p| p.list? && predicate.eql?(p)}.inject({}) do |memo, li|
                memo.merge(li => ps[li])
              end
            elsif ps.has_key?(predicate)
              { predicate => ps[predicate] }
            else
              []
            end
            ps.each do |p, os|
              os.each do |o, object_options|
                next unless object.nil? || object.eql?(o)
                yield RDF::Statement.new(s, p, o, object_options.merge(graph_name: c.equal?(DEFAULT_GRAPH) ? nil : c))
              end
            end
          end
        end
      else
        enum_for(:query_pattern, pattern, **options)
      end
    end

    ##
    # @private
    # @see RDF::Mutable#insert
    def insert_statement(statement)
      @data = insert_to(@data, statement)
    end

    ##
    # @private
    # @see RDF::Mutable#delete
    def delete_statement(statement)
      @data = delete_from(@data, statement)
    end

    ##
    # @private
    # @see RDF::Mutable#clear
    def clear_statements
      @data = @data.clear
    end

    ##
    # @private
    # @return [Hash]
    def data
      @data
    end

    ##
    # @private
    # @return [Hash]
    def data=(hash)
      @data = hash
    end

    private

    ##
    # @private
    # @see #has_statement
    def has_statement_in?(data, statement)
      s, p, o, g = statement.to_quad
      g ||= DEFAULT_GRAPH

      data.has_key?(g) &&
        data[g].has_key?(s) &&
        data[g][s].has_key?(p) &&
        data[g][s][p].has_key?(o)
    end

    ##
    # @private
    # @return [Hash] a new, updated hash 
    def insert_to(data, statement)
      raise ArgumentError, "Statement #{statement.inspect} is incomplete" if statement.incomplete?

      s, p, o, c = statement.to_quad
      c ||= DEFAULT_GRAPH
      unless has_statement_in?(data, statement)
        data          = data.has_key?(c)       ? data.dup       : data.merge(c => {})
        data[c]       = data[c].has_key?(s)    ? data[c].dup    : data[c].merge(s => {})
        data[c][s]    = data[c][s].has_key?(p) ? data[c][s].dup : data[c][s].merge(p => {})
        data[c][s][p] = data[c][s][p].merge(o => statement.options)
      end

      # If statement is inferred, make sure that it is marked as inferred in the dataset.
      data[c][s][p][o][:inferred] = true if statement.options[:inferred]

      data
    end
    
    ##
    # @private
    # @return [Hash] a new, updated hash 
    def delete_from(data, statement)
      if has_statement_in?(data, statement)
        s, p, o, g = statement.to_quad
        g = DEFAULT_GRAPH unless supports?(:graph_name)
        g ||= DEFAULT_GRAPH

        os   = data[g][s][p].dup.delete_if {|k,v| k == o}
        ps   = os.empty? ? data[g][s].dup.delete_if {|k,v| k == p} : data[g][s].merge(p => os)
        ss   = ps.empty? ? data[g].dup.delete_if    {|k,v| k == s} : data[g].merge(s => ps)
        return ss.empty? ? data.dup.delete_if       {|k,v| k == g} : data.merge(g => ss)
      end
      data
    end
  end
end
