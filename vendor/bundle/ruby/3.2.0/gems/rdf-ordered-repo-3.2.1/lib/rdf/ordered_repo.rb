require 'rdf'

module RDF
  ##
  # Sub-class of RDF::Repository with order-preserving properties.
  class OrderedRepo < RDF::Repository
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
    # @option options [Boolean]   :transaction_class (RDF::Transaction::SerializedTransaction)
    #   Specifies the RDF::Transaction implementation to use in this Repository.
    # @yield  [repository]
    # @yieldparam [Repository] repository
    def initialize(uri: nil, title: nil, transaction_class: RDF::Transaction::SerializedTransaction, **options, &block)
      @data = options.delete(:data) || {}
      super do
        @tx_class = transaction_class
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
      when :rdfstar          then true
      when :snapshots        then true
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
    # @overload graph?
    #   Returns `false` to indicate that this is not a graph.
    #
    #   @return [Boolean]
    # @overload graph?(name)
    #   Returns `true` if `self` contains the given RDF graph_name.
    #
    #   @param  [RDF::Resource, false] graph_name
    #     Use value `false` to query for the default graph_name
    #   @return [Boolean]
    def graph?(*args)
      case args.length
      when 0 then false
      when 1 then @data.key?(args.first)
      else raise ArgumentError("wrong number of arguments (given #{args.length}, expected 0 or 1)")
      end
    end
    alias_method :has_graph?, :graph?

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
    # @overload statement?
    #   Returns `false` indicating this is not an RDF::Statemenet.
    #   @return [Boolean]
    #   @see RDF::Value#statement?
    # @overload statement?(statement)
    #   @private
    #   @see    RDF::Enumerable#statement?
    def statement?(*args)
      case args.length
      when 0 then false
      when 1 then args.first && statement_in?(@data, args.first)
      else raise ArgumentError("wrong number of arguments (given #{args.length}, expected 0 or 1)")
      end
    end
    alias_method :has_statement?, :statement?

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
      :snapshot
    end

    ##
    # A readable & queryable snapshot of the repository for isolated reads. 
    # 
    # @return [Dataset] an immutable Dataset containing a current snapshot of
    #   the Repository contents.
    #
    # @see Mutable#snapshot
    def snapshot
      self.class.new(data: @data).freeze
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
      snapshot = @data
      if block_given?
        graph_name  = pattern.graph_name
        subject     = pattern.subject
        predicate   = pattern.predicate
        object      = pattern.object

        cs = snapshot.has_key?(graph_name) ? { graph_name => snapshot[graph_name] } : snapshot

        cs.each do |c, ss|
          next unless graph_name.nil? ||
                      graph_name == DEFAULT_GRAPH && !c ||
                      graph_name.eql?(c)

          ss = if subject.nil? || subject.is_a?(RDF::Query::Variable)
            ss
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
      @data = @data.class.new
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
    # @see #statement?
    def statement_in?(data, statement)
      s, p, o, g = statement.to_quad
      g ||= DEFAULT_GRAPH

      data.key?(g) &&
        data[g].key?(s) &&
        data[g][s].key?(p) &&
        data[g][s][p].key?(o)
    end
    alias_method :has_statement_in?, :statement_in?

    ##
    # @private
    # @return [Hash] a new, updated hash 
    def insert_to(data, statement)
      raise ArgumentError, "Statement #{statement.inspect} is incomplete" if statement.incomplete?

      unless statement_in?(data, statement)
        s, p, o, c = statement.to_quad
        c ||= DEFAULT_GRAPH

        data          = data.has_key?(c)       ? data.dup       : data.merge(c => {})
        data[c]       = data[c].has_key?(s)    ? data[c].dup    : data[c].merge(s => {})
        data[c][s]    = data[c][s].has_key?(p) ? data[c][s].dup : data[c][s].merge(p => {})
        data[c][s][p] = data[c][s][p].merge(o => statement.options)
      end
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

    module VERSION
      VERSION_FILE = File.expand_path("../../../VERSION", __FILE__)
      MAJOR, MINOR, TINY, EXTRA = File.read(VERSION_FILE).chop.split(".")

      STRING = [MAJOR, MINOR, TINY, EXTRA].compact.join('.')

      ##
      # @return [String]
      def self.to_s()   STRING end

      ##
      # @return [String]
      def self.to_str() STRING end

      ##
      # @return [Array(Integer, Integer, Integer)]
      def self.to_a() STRING.split(".") end
    end
  end
end
