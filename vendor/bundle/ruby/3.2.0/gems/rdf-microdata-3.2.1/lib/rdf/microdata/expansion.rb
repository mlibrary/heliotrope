module RDF::Microdata
  ##
  # The Expansion module performs a subset of OWL entailment rules on the base class,
  # which implementes RDF::Readable.
  module Expansion
    ##
    # Perform vocabulary expansion on the resulting default graph.
    #
    #   Vocabulary expansion relies on a sub-set of OWL [OWL2-PROFILES](http://www.w3.org/TR/2009/REC-owl2-profiles-20091027/#Reasoning_in_OWL_2_RL_and_RDF_Graphs_using_Rules) entailment to add triples to the default graph based on rules and property/class relationships described in referenced vocabularies.
    #
    # For all objects that are the target of an rdfa:usesVocabulary property, load the IRI into a repository.
    #
    # Subsequently, perform OWL expansion using rules prp-spo1, prp-eqp1, and prp-eqp2 placing resulting triples into the default graph. Iterate on this step until no more triples are added.
    #
    # @example
    #    scm-spo
    #    {pq rdfs:subPropertyOf pw . pw rdfs:subPropertyOf p3}
    #       => {p1 rdfs:subPropertyOf p3}
    #
    #    rdprp-spo1fs7
    #    {p1 rdfs:subPropertyOf p2 . x p1 y} => {x p2 y}
    #
    # @return [RDF::Graph]
    # @see [OWL2 PROFILES][]
    def expand
      repo = RDF::Repository.new
      repo << self  # Add default graph
      
      log_debug("expand") {"Loaded #{repo.size} triples into default graph"}
      
      repo = owl_entailment(repo)

      # Return graph with default graph
      graph = RDF::Graph.new
      repo.statements.each {|st| graph << st}
      graph
    end

    def rule(name, &block)
      Rule.new(name, **@options, &block)
    end

    ##
    # An entailment rule
    #
    # Takes a list of antecedent patterns used to find solutions against a queryable
    # object. Yields each consequent with bindings from the solution
    class Rule
      include RDF::Util::Logger

      # @!attribute [r]
      # @return [Array<RDF::Query::Pattern>] patterns necessary to invoke this rule
      attr_reader :antecedents

      # @!attribute [r] consequents
      # @return [Array<RDF::Query::Pattern>] result of this rule
      attr_reader :consequents

      # @!attribute [r] name
      # @return [String] Name of this rule
      attr_reader :name

      ##
      # @example
      #   r = Rule.new("scm-spo") do
      #     antecedent :p1, RDF::RDFS.subPropertyOf, :p2
      #     antecedent :p2, RDF::RDFS.subPropertyOf, :p3
      #     consequent :p1, RDF::RDFS.subPropertyOf, :p3, "t-box"
      #   end
      #
      #   r.execute(queryable) {|statement| puts statement.inspect}
      #
      # @param [String] name
      def initialize(name, **options, &block)
        @antecedents = []
        @consequents = []
        @options = options.dup
        @name = name

        if block_given?
          case block.arity
            when 1 then block.call(self)
            else instance_eval(&block)
          end
        end
      end

      def antecedent(subject, prediate, object)
        antecedents << RDF::Query::Pattern.new(subject, prediate, object)
      end

      def consequent(subject, prediate, object)
        consequents << RDF::Query::Pattern.new(subject, prediate, object)
      end
      
      ##
      # Execute the rule against queryable, yielding each consequent with bindings
      #
      # @param [RDF::Queryable] queryable
      # @yield [statement]
      # @yieldparam [RDF::Statement] statement
      def execute(queryable)
        RDF::Query.new(antecedents).execute(queryable).each do |solution|
          nodes = {}
          consequents.each do |consequent|
            terms = {}
            [:subject, :predicate, :object].each do |r|
              terms[r] = case o = consequent.send(r)
              when RDF::Node            then nodes[o] ||= RDF::Node.new
              when RDF::Query::Variable then solution[o]
              else                           o
              end
            end

            yield RDF::Statement.from(terms)
          end
        end
      end
    end

  private

    RULES = [
      Rule.new("prp-spo1") do
        antecedent :p1, RDF::RDFS.subPropertyOf, :p2
        antecedent :x, :p1, :y
        consequent :x, :p2, :y
      end,
      Rule.new("prp-eqp1") do
        antecedent :p1, RDF::OWL.equivalentProperty, :p2
        antecedent :x, :p1, :y
        consequent :x, :p2, :y
      end,
      Rule.new("prp-eqp2") do
        antecedent :p1, RDF::OWL.equivalentProperty, :p2
        antecedent :x, :p2, :y
        consequent :x, :p1, :y
      end,
    ]

    ##
    # Perform OWL entailment rules on enumerable
    # @param [RDF::Enumerable] repo
    # @return [RDF::Enumerable]
    def owl_entailment(repo)
      old_count = 0

      while old_count < (count = repo.count)
        log_debug("entailment", "old: #{old_count} count: #{count}")
        old_count = count

        RULES.each do |rule|
          rule.execute(repo) do |statement|
            log_debug("entailment(#{rule.name})") {statement.inspect}
            repo << statement
          end
        end
      end
      
      log_debug("entailment", "final count: #{count}")
      repo
    end
  end
end
