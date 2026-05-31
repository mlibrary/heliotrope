module RDF::N3
  ##
  # Sub-class of RDF::List which uses a native representation of values and allows recursive lists.
  #
  # Also serves as the vocabulary URI for expanding other methods
  class List < RDF::List
    # Allow a list to be treated as a term in a statement.
    include ::RDF::Term

    URI = RDF::URI("http://www.w3.org/2000/10/swap/list#")

    # Returns a vocubulary term
    def self.method_missing(property, *args, &block)
      property = RDF::Vocabulary.camelize(property.to_s)
      if args.empty? && !to_s.empty?
        RDF::Vocabulary::Term.intern("#{URI}#{property}", attributes: {})
      else
        super
      end
    end

    ##
    # Returns the base URI for this vocabulary.
    #
    # @return [URI]
    def self.to_uri
      URI
    end

    ##
    # Attempts to create an RDF::N3::List from subject, or returns the node as is, if unable.
    #
    # @param [RDF::Resource] subject
    # @return [RDF::List, RDF::Resource] returns either the original resource, or a list based on that resource
    def self.try_list(subject, graph)
      return subject unless subject && (subject.node? || subject.uri? && subject == RDF.nil)
      ln = RDF::List.new(subject: subject, graph: graph)
      return subject unless ln.valid?

      # Return a new list, outside of this queryable, with any embedded lists also expanded
      values = ln.to_a.map {|li| try_list(li, graph)}
      RDF::N3::List.new(subject: subject, graph: graph, values: values)
    end

    ##
    # Initializes a newly-constructed list.
    #
    # Instantiates a new list based at `subject`, which **must** be an RDF::Node. List may be initialized using passed `values`.
    #
    # @example add constructed list to existing graph
    #     l = RDF::N3::List(values: (1, 2, 3))
    #     g = RDF::Graph.new << l
    #     g.count # => l.count
    #
    # If values is not provided, but subject and graph are, then will attempt to recursively represent lists.
    #
    # @param  [RDF::Resource]         subject (RDF.nil)
    #   Subject should be an {RDF::Node}, not a {RDF::URI}. A list with an IRI head will not validate, but is commonly used to detect if a list is valid.
    # @param  [RDF::Graph]        graph (RDF::Graph.new)
    # @param  [Array<RDF::Term>]  values
    #   Any values which are not terms are coerced to `RDF::Literal`.
    # @yield  [list]
    # @yieldparam [RDF::List] list
    def initialize(subject: nil, graph: nil, values: nil, &block)
      @subject = subject || (Array(values).empty? ? RDF.nil : RDF::Node.new)
      @graph = graph
      @valid = true

      @values = case
      when values
        values.map do |v|
          # Convert values, as necessary.
          case v
          when RDF::Value then v.to_term
          when Symbol     then RDF::Node.intern(v)
          when Array      then RDF::N3::List.new(values: v)
          when nil        then RDF.nil
          else                 RDF::Literal.new(v)
          end
        end
      when subject && graph
        ln = RDF::List.new(subject: subject, graph: graph)
        @valid = ln.valid?
        ln.to_a.map {|li| self.class.try_list(li, graph)}
      else
        []
      end
    end

    ##
    # Lists are valid, unless established via RDF::List, in which case they are only valid if the RDF::List is valid.
    #
    # @return [Boolean]
    def valid?; @valid; end

    ##
    # @see RDF::Value#==
    def ==(other)
      case other
      when Array, RDF::List then to_a == other.to_a
      else
        false
      end
    end

    ##
    # The list hash is the hash of it's members.
    #
    # @see RDF::Value#hash
    def hash
      to_a.hash
    end

    ##
    # Element Assignment — Sets the element at `index`, or replaces a subarray from the `start` index for `length` elements, or replaces a subarray specified by the `range` of indices.
    #
    # @overload []=(index, term)
    #   Replaces the element at `index` with `term`.
    #   @param [Integer] index
    #   @param [RDF::Term] term
    #     A non-RDF::Term is coerced to a Literal.
    #   @return [RDF::Term]
    #   @raise [IndexError]
    #
    # @overload []=(start, length, value)
    #   Replaces a subarray from the `start` index for `length` elements with `value`. Value is a {RDF::Term}, Array of {RDF::Term}, or {RDF::List}.
    #   @param [Integer] start
    #   @param [Integer] length
    #   @param [RDF::Term, Array<RDF::Term>, RDF::List] value
    #     A non-RDF::Term is coerced to a Literal.
    #   @return [RDF::Term, RDF::List]
    #   @raise [IndexError]
    #
    # @overload []=(range, value)
    #   Replaces a subarray from the `start` index for `length` elements with `value`. Value is a {RDF::Term}, Array of {RDF::Term}, or {RDF::List}.
    #   @param [Range] range
    #   @param [RDF::Term, Array<RDF::Term>, RDF::List] value
    #     A non-RDF::Term is coerced to a Literal.
    #   @return [RDF::Term, RDF::List]
    #   @raise [IndexError]
    def []=(*args)
      value = case args.last
      when Array then args.last
      when RDF::List then args.last.to_a
      else [args.last]
      end.map do |v|
        # Convert values, as necessary.
        case v
        when RDF::Value then v.to_term
        when Symbol     then RDF::Node.intern(v)
        when Array      then RDF::N3::List.new(values: v)
        when nil        then RDF.nil
        else                 RDF::Literal.new(v)
        end
      end

      ret = case args.length
      when 3
        start, length = args[0], args[1]
        @subject = nil if start == 0
        @values[start, length] = value
      when 2
        case args.first
        when Integer
          raise ArgumentError, "Index form of []= takes a single term" if args.last.is_a?(Array)
          @values[args.first] = value.first
        when Range
          @values[args.first] = value
        else
          raise ArgumentError, "Index form of must use an integer or range"
        end
      else
        raise ArgumentError, "List []= takes one or two index values"
      end

      # Fill any nil entries in @values with rdf:nil
      @values.map! {|v| v || RDF.nil}

      @subject = RDF.nil if @values.empty?
      @subject ||= RDF::Node.new
      ret # Returns inserted values
    end

    ##
    # Appends an element to the head of this list. Existing references are not updated, as the list subject changes as a side-effect.
    #
    # @example
    #   RDF::List[].unshift(1).unshift(2).unshift(3) #=> RDF::List[3, 2, 1]
    #
    # @param  [RDF::Term, Array<RDF::Term>, RDF::List] value
    #   A non-RDF::Term is coerced to a Literal
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-unshift
    #
    def unshift(value)
      value = normalize_value(value)
      @values.unshift(value)
      @subject = nil

      return self
    end

    ##
    # Removes and returns the element at the head of this list.
    #
    # @example
    #   RDF::List[1,2,3].shift              #=> 1
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-shift
    def shift
      return nil if empty?
      @subject = nil
      @values.shift
    end

    ##
    # Empties this list
    #
    # @example
    #   RDF::List[1, 2, 2, 3].clear    #=> RDF::List[]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-clear
    def clear
      @values.clear
      @subject = nil
      self
    end

    ##
    # Appends an element to the tail of this list.
    #
    # @example
    #   RDF::List[] << 1 << 2 << 3              #=> RDF::List[1, 2, 3]
    #
    # @param  [RDF::Term] value
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-3C-3C
    def <<(value)
      value = normalize_value(value)
      @subject = nil
      @values << value
      self
    end

    ##
    # Returns `true` if this list is empty.
    #
    # @example
    #   RDF::List[].empty?                      #=> true
    #   RDF::List[1, 2, 3].empty?               #=> false
    #
    # @return [Boolean]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-empty-3F
    def empty?
      @values.empty?
    end

    ##
    # Returns the length of this list.
    #
    # @example
    #   RDF::List[].length                      #=> 0
    #   RDF::List[1, 2, 3].length               #=> 3
    #
    # @return [Integer]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-length
    def length
      @values.length
    end

    ##
    # Returns the index of the first element equal to `value`, or `nil` if
    # no match was found.
    #
    # @example
    #   RDF::List['a', 'b', 'c'].index('a')     #=> 0
    #   RDF::List['a', 'b', 'c'].index('d')     #=> nil
    #
    # @param  [RDF::Term] value
    # @return [Integer]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-index
    def index(value)
      @values.index(value)
    end

    ##
    # Returns element at `index` with default.
    #
    # @example
    #   RDF::List[1, 2, 3].fetch(0)             #=> RDF::Literal(1)
    #   RDF::List[1, 2, 3].fetch(4)             #=> IndexError
    #   RDF::List[1, 2, 3].fetch(4, nil)        #=> nil
    #   RDF::List[1, 2, 3].fetch(4) { |n| n*n } #=> 16
    #
    # @return [RDF::Term, nil]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000420
    def fetch(*args, &block)
      @values.fetch(*args, &block)
    end

    ##
    # Returns the element at `index`.
    #
    # @example
    #   RDF::List[1, 2, 3].at(0)                #=> 1
    #   RDF::List[1, 2, 3].at(4)                #=> nil
    #
    # @return [RDF::Term, nil]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-at
    def at(index)
      @values.at(index)
    end

    ##
    # Returns the first element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].first               #=> RDF::Literal(1)
    #
    # @return [RDF::Term]
    def first
      @values.first
    end

    ##
    # Returns the last element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].last                 #=> RDF::Literal(10)
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-2.2.2/Array.html#method-i-last
    def last
      @values.last
    end

    ##
    # Returns a list containing all but the first element of this list.
    #
    # @example
    #   RDF::List[1, 2, 3].rest                 #=> RDF::List[2, 3]
    #
    # @return [RDF::List]
    def rest
      self.class.new(values: @values[1..-1])
    end

    ##
    # Returns a list containing the last element of this list.
    #
    # @example
    #   RDF::List[1, 2, 3].tail                 #=> RDF::List[3]
    #
    # @return [RDF::List]
    def tail
      self.class.new(values: @values[-1..-1])
    end

    ##
    # Yields each element in this list.
    #
    # @example
    #   RDF::List[1, 2, 3].each do |value|
    #     puts value.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    http://ruby-doc.org/core-1.9/classes/Enumerable.html
    def each(&block)
      return to_enum unless block_given?

      @values.each(&block)
    end

    ##
    # Yields each statement constituting this list. Uses actual statements if a graph was set, otherwise, the saved values.
    #
    # This will recursively get statements for sub-lists as well.
    #
    # @example
    #   RDF::List[1, 2, 3].each_statement do |statement|
    #     puts statement.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    RDF::Enumerable#each_statement
    def each_statement(&block)
      return enum_statement unless block_given?

      if graph
        RDF::List.new(subject: subject, graph: graph).each_statement(&block)
      elsif @values.length > 0
        # Create a subject for each entry based on the subject bnode
        subjects = (0..(@values.count-1)).map {|ndx| ndx > 0 ? RDF::Node.intern("#{subject.id}_#{ndx}") : subject}
        *values, last = @values
        while !values.empty?
          subj = subjects.shift
          value = values.shift
          block.call(RDF::Statement(subj, RDF.first, value.list? ? value.subject : value))
          block.call(RDF::Statement(subj, RDF.rest, subjects.first))
        end
        subj = subjects.shift
        block.call(RDF::Statement(subj, RDF.first, last.list? ? last.subject : last))
        block.call(RDF::Statement(subj, RDF.rest, RDF.nil))
      end

      # If a graph was used, also get statements from sub-lists
      @values.select(&:list?).each {|li| li.each_statement(&block)}
    end

    ##
    # Yields each subject term constituting this list along with sub-lists.
    #
    # @example
    #   RDF::List[1, 2, 3].each_subject do |subject|
    #     puts subject.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    RDF::Enumerable#each
    def each_subject(&block)
      return enum_subject unless block_given?

      each_statement {|st| block.call(st.subject) if st.predicate == RDF.rest}
    end

    ##
    # Enumerate via depth-first recursive descent over list members, yielding each member
    # @yield term
    # @yieldparam [RDF::Term] term
    # @return [Enumerator]
    def each_descendant(&block)
      if block_given?
        each do |term|
          term.each_descendant(&block) if term.list?
          block.call(term)
        end
      end
      enum_for(:each_descendant)
    end

    ##
    # Does this list, or any recusive list have any blank node members?
    #
    # @return [Boolean]
    def has_nodes?
      @values.any? {|e| e.node? || e.list? && e.has_nodes?}
    end

    ##
    # Substitutes blank node members with existential variables, recusively.
    #
    # @param [RDF::Node] scope
    # @return [RDF::N3::List]
    def to_ndvar(scope)
      values = @values.map do |e|
        case e
        when RDF::Node     then e.to_ndvar(scope)
        when RDF::N3::List then e.to_ndvar(scope)
        else                    e
        end
      end
      RDF::N3::List.new(values: values)
    end

    ##
    # Returns the elements in this list as an array.
    #
    # @example
    #   RDF::List[].to_a                        #=> []
    #   RDF::List[1, 2, 3].to_a                 #=> [RDF::Literal(1), RDF::Literal(2), RDF::Literal(3)]
    #
    # @return [Array]
    def to_a
      @values
    end

    ##
    # Checks pattern equality against another list, considering nesting.
    #
    # @param  [List, Array] other
    # @return [Boolean]
    def eql?(other)
      other = RDF::N3::List[*other] if other.is_a?(Array)
      return false if !other.is_a?(RDF::List) || count != other.count
      @values.each_with_index do |li, ndx|
        case li
        when RDF::Query::Pattern, RDF::N3::List
          return false unless li.eql?(other.at(ndx))
        else
          return false unless li == other.at(ndx)
        end
      end
      true
    end

    ##
    # A list is variable if any of its members are variable?
    #
    # @return [Boolean]
    def variable?
      @values.any?(&:variable?)
    end

    ##
    # Return the variables contained this list
    # @return [Array<RDF::Query::Variable>]
    def vars
      @values.vars
    end

    ##
    # Returns all variables in this list.
    #
    # Note: this returns a hash containing distinct variables only.
    #
    # @return [Hash{Symbol => Variable}]
    def variables
      @values.inject({}) do |hash, li|
        li.respond_to?(:variables) ? hash.merge(li.variables) : hash
      end
    end

    ##
    # Returns the number of variables in this list, recursively.
    #
    # @return [Integer]
    def variable_count
      variables.length
    end

    ##
    # Returns all values the list in the same pattern position
    #
    # @param [Symbol] var
    # @param [RDF::N3::List] list
    # @return [Array<RDF::Term>]
    def var_values(var, list)
      results = []
      @values.each_index do |ndx|
        maybe_var = @values[ndx]
        next unless maybe_var.respond_to?(:var_values)
        results.push(*Array(maybe_var.var_values(var, list.at(ndx))))
      end
      results.flatten.compact
    end

    ##
    # Evaluates the list using the given variable `bindings`.
    #
    # @param  [Hash{Symbol => RDF::Term}] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::N3::List]
    # @see SPARQL::Algebra::Expression.evaluate
    def evaluate(bindings, formulae: {}, **options)
      # if values are constant, simply return ourselves
      return self if to_a.none? {|li| li.node? || li.variable?}
      bindings = bindings.to_h unless bindings.is_a?(Hash)
      # Create a new list subject using a combination of the current subject and a hash of the binding values
      subj = "#{subject.id}_#{bindings.values.sort.hash}"
      values = to_a.map do |o|
        o = o.evaluate(bindings, formulae: formulae, **options) || o
      end
      RDF::N3::List.new(subject: RDF::Node.intern(subj), values: values)
    end

    ##
    # Returns a query solution constructed by binding any variables in this list with the corresponding terms in the given `list`.
    #
    # @param  [RDF::N3::List] list
    #   a native list with patterns to bind.
    # @return [RDF::Query::Solution]
    # @see RDF::Query::Pattern#solution
    def solution(list)
      RDF::Query::Solution.new do |solution|
        @values.each_with_index do |li, ndx|
          if li.respond_to?(:solution)
            solution.merge!(li.solution(list[ndx]))
          elsif li.is_a?(RDF::Query::Variable)
            solution[li.to_sym] = list[ndx]
          end
        end
      end
    end

    ##
    # Returns the base representation of this term.
    #
    # @return [Sring]
    def to_base
      "(#{@values.map(&:to_base).join(' ')})"
    end

    # Transform Statement into an SXP
    # @return [Array]
    def to_sxp_bin
      to_a.to_sxp_bin
    end

    ##
    # Creates a new list by recusively mapping the values of the list
    #
    # @return [RDF::N3::list]
    def transform(&block)
      values = self.to_a.map {|v| v.list? ? v.map(&block) : block.call(v)}
      RDF::N3::List.new(values: values)
    end

    private

    ##
    # Normalizes `Array` to `RDF::List` and `nil` to `RDF.nil`.
    #
    # @param value [Object]
    # @return [RDF::Value, Object] normalized value
    def normalize_value(value)
      case value
      when RDF::Value then value.to_term
      when Array      then RDF::N3::List.new(values: value)
      when Symbol     then RDF::Node.intern(value)
      when nil        then RDF.nil
      else                 RDF::Literal.new(value)
      end
    end
  end
end
