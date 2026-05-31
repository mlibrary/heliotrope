# Extensions to RDF core classes to support reasoning
require 'rdf'

module RDF
  class URI
    class << self
      @@entailments = {}

      ##
      # Add an entailment method. The method accepts no arguments, and returns or yields an array of values associated with the particular entailment method
      # @param [Symbol] method
      # @param [Proc] proc
      def add_entailment(method, proc)
        @@entailments[method] = proc
      end
    end

    ##
    # Perform an entailment on this term.
    #
    # @param [Symbol] method A registered entailment method
    # @yield term
    # @yieldparam [Term] term
    # @return [Array<Term>]
    def entail(method, &block)
      self.send(@@entailments.fetch(method), &block)
    end

    ##
    # Determine if the domain of a property term is consistent with the specified resource in `queryable`.
    #
    # @param [RDF::Resource] resource
    # @param [RDF::Queryable] queryable
    # @param [Hash{Symbol => Object}] options ({})
    # @option options [Array<RDF::Vocabulary::Term>] :types
    #   Fully entailed types of resource, if not provided, they are queried
    def domain_compatible?(resource, queryable, options = {})
      %w(owl rdfs schema).map {|r| "domain_compatible_#{r}?".to_sym}.all? do |meth|
        !self.respond_to?(meth) || self.send(meth, resource, queryable, options)
      end
    end

    ##
    # Determine if the range of a property term is consistent with the specified resource in `queryable`.
    #
    # Specific entailment regimes should insert themselves before this to apply the appropriate semantic condition
    #
    # @param [RDF::Resource] resource
    # @param [RDF::Queryable] queryable
    # @param [Hash{Symbol => Object}] options ({})
    # @option options [Array<RDF::Vocabulary::Term>] :types
    #   Fully entailed types of resource, if not provided, they are queried
    def range_compatible?(resource, queryable, options = {})
      %w(owl rdfs schema).map {|r| "range_compatible_#{r}?".to_sym}.all? do |meth|
        !self.respond_to?(meth) || self.send(meth, resource, queryable, options)
      end
    end
  end

  class Node
    class << self
      @@entailments = {}

      ##
      # Add an entailment method. The method accepts no arguments, and returns or yields an array of values associated with the particular entailment method
      # @param [Symbol] method
      # @param [Proc] proc
      def add_entailment(method, proc)
        @@entailments[method] = proc
      end
    end

    ##
    # Perform an entailment on this term.
    #
    # @param [Symbol] method A registered entailment method
    # @yield term
    # @yieldparam [Term] term
    # @return [Array<Term>]
    def entail(method, &block)
      self.send(@@entailments.fetch(method), &block)
    end

    ##
    # Determine if the domain of a property term is consistent with the specified resource in `queryable`.
    #
    # @param [RDF::Resource] resource
    # @param [RDF::Queryable] queryable
    # @param [Hash{Symbol => Object}] options ({})
    # @option options [Array<RDF::Vocabulary::Term>] :types
    #   Fully entailed types of resource, if not provided, they are queried
    def domain_compatible?(resource, queryable, options = {})
      %w(owl rdfs schema).map {|r| "domain_compatible_#{r}?".to_sym}.all? do |meth|
        !self.respond_to?(meth) || self.send(meth, resource, queryable, **options)
      end
    end

    ##
    # Determine if the range of a property term is consistent with the specified resource in `queryable`.
    #
    # Specific entailment regimes should insert themselves before this to apply the appropriate semantic condition
    #
    # @param [RDF::Resource] resource
    # @param [RDF::Queryable] queryable
    # @param [Hash{Symbol => Object}] options ({})
    # @option options [Array<RDF::Vocabulary::Term>] :types
    #   Fully entailed types of resource, if not provided, they are queried
    def range_compatible?(resource, queryable, options = {})
      %w(owl rdfs schema).map {|r| "range_compatible_#{r}?".to_sym}.all? do |meth|
        !self.respond_to?(meth) || self.send(meth, resource, queryable, options)
      end
    end
  end

  class Statement
    class << self
      @@entailments = {}

      ##
      # Add an entailment method. The method accepts no arguments, and returns or yields an array of values associated with the particular entailment method
      # @param [Symbol] method
      # @param [Proc] proc
      def add_entailment(method, proc)
        @@entailments[method] = proc
      end
    end

    ##
    # Perform an entailment on this term.
    #
    # @param [Symbol] method A registered entailment method
    # @yield term
    # @yieldparam [Term] term
    # @return [Array<Term>]
    def entail(method, &block)
      self.send(@@entailments.fetch(method), &block)
    end
  end

  module Enumerable
    class << self
      @@entailments = {}

      ##
      # Add an entailment method. The method accepts no arguments, and returns or yields an array of values associated with the particular entailment method
      # @param [Symbol] method
      # @param [Proc] proc
      def add_entailment(method, proc)
        @@entailments[method] = proc
      end
    end

    ##
    # Perform entailments on this enumerable in a single pass, yielding entailed statements.
    #
    # For best results, either run rules separately expanding the enumberated graph, or run repeatedly until no new statements are added to the enumerable containing both original and entailed statements. As `:subClassOf` and `:subPropertyOf` entailments are implicitly recursive, this may not be necessary except for extreme cases.
    #
    # @overload entail
    #   @param [Array<Symbol>] *rules
    #     Registered entailment method(s).
    #     
    #   @yield statement
    #   @yieldparam [RDF::Statement] statement
    #   @return [void]
    #
    # @overload entail
    #   @param [Array<Symbol>] *rules Registered entailment method(s)
    #   @return [Enumerator]
    def entail(*rules, &block)
      if block_given?
        rules = %w(subClassOf subPropertyOf domain range).map(&:to_sym) if rules.empty?

        self.each do |statement|
          rules.each {|rule| statement.entail(rule, &block)}
        end
      else
        # Otherwise, return an Enumerator with the entailed statements
        this = self
        RDF::Queryable::Enumerator.new do |yielder|
          this.entail(*rules) {|y| yielder << y}
        end
      end
    end
  end

  module Mutable
    class << self
      @@entailments = {}

      ##
      # Add an entailment method. The method accepts no arguments, and returns or yields an array of values associated with the particular entailment method
      # @param [Symbol] method
      # @param [Proc] proc
      def add_entailment(method, proc)
        @@entailments[method] = proc
      end
    end

    # Return a new mutable, composed of original and entailed statements
    #
    # @param [Array<Symbol>] rules Registered entailment method(s)
    # @return [RDF::Mutable]
    # @see [RDF::Enumerable#entail]
    def entail(*rules, &block)
      self.dup.entail!(*rules)
    end

    # Add entailed statements to the mutable
    #
    # @param [Array<Symbol>] rules Registered entailment method(s)
    # @return [RDF::Mutable]
    # @see [RDF::Enumerable#entail]
    def entail!(*rules, &block)
      rules = %w(subClassOf subPropertyOf domain range).map(&:to_sym) if rules.empty?
      statements = []

      self.each do |statement|
        rules.each do |rule|
          statement.entail(rule) do |st|
            statements << st
          end
        end
      end
      self.insert(*statements)
      self
    end
  end

  module Queryable
    # Lint a queryable, presuming that it has already had RDFS entailment expansion.
    # @return [Hash{Symbol => Hash{Symbol => Array<String>}}] messages found for classes and properties by term
    def lint
      messages = {}

      # Check for defined classes in known vocabularies
      self.query({predicate: RDF.type}) do |stmt|
        vocab = RDF::Vocabulary.find(stmt.object)
        term = (RDF::Vocabulary.find_term(stmt.object) rescue nil) if vocab
        pname = term ? term.pname : stmt.object.pname
        
        # Must be a defined term, not in RDF or RDFS vocabularies
        if term && term.class?
          # Warn against using a deprecated term
          superseded = term.properties[:'http://schema.org/supersededBy']
          superseded = superseded.pname if superseded.respond_to?(:pname)
          (messages[:class] ||= {})[pname] = ["Term is superseded by #{superseded}"] if superseded
        else
          (messages[:class] ||= {})[pname] = ["No class definition found"] unless vocab.nil? || [RDF::RDFV, RDF::RDFS].include?(vocab)
        end
      end

      # Check for defined predicates in known vocabularies and domain/range
      resource_types = {}
      self.each_statement do |stmt|
        vocab = RDF::Vocabulary.find(stmt.predicate)
        term = (RDF::Vocabulary.find_term(stmt.predicate) rescue nil) if vocab
        pname = term ? term.pname : stmt.predicate.pname

        # Must be a valid statement
        begin
          stmt.validate!
        rescue
          ((messages[:statement] ||= {})[pname] ||= []) << "Triple #{stmt.to_ntriples} is invalid"
        end

        # Must be a defined property
        if term.respond_to?(:property?) && term.property?
          # Warn against using a deprecated term
          superseded = term.properties[:'http://schema.org/supersededBy']
          superseded = superseded.pname if superseded.respond_to?(:pname)
          (messages[:property] ||= {})[pname] = ["Term is superseded by #{superseded}"] if superseded
        else
          ((messages[:property] ||= {})[pname] ||= []) << "No property definition found" unless vocab.nil?
          next
        end

        # See if type of the subject is in the domain of this predicate
        resource_types[stmt.subject] ||= self.query({subject: stmt.subject, predicate: RDF.type}).
        map {|s| (t = (RDF::Vocabulary.find_term(s.object) rescue nil)) && t.entail(:subClassOf)}.
          flatten.
          uniq.
          compact

        unless term.domain_compatible?(stmt.subject, self, types: resource_types[stmt.subject])
          ((messages[:property] ||= {})[pname] ||= []) << if !term.domain.empty?
           "Subject #{show_resource(stmt.subject)} not compatible with domain (#{Array(term.domain).map {|d| d.pname|| d}.join(',')})"
          else
            domains = Array(term.domainIncludes) +
                      Array(term.properties[:'https://schema.org/domainIncludes'])
            "Subject #{show_resource(stmt.subject)} not compatible with domainIncludes (#{domains.map {|d| d.pname|| d}.join(',')})"
          end
        end

        # Make sure that if ranges are defined, the object has an appropriate type
        resource_types[stmt.object] ||= self.query({subject: stmt.object, predicate: RDF.type}).
          map {|s| (t = (RDF::Vocabulary.find_term(s.object) rescue nil)) && t.entail(:subClassOf)}.
          flatten.
          uniq.
          compact if stmt.object.resource?

        unless term.range_compatible?(stmt.object, self, types: resource_types[stmt.object])
          ((messages[:property] ||= {})[pname] ||= []) << if !term.range.empty?
           "Object #{show_resource(stmt.object)} not compatible with range (#{Array(term.range).map {|d| d.pname|| d}.join(',')})"
          else
            ranges = Array(term.rangeIncludes) +
                      Array(term.properties[:'https://schema.org/rangeIncludes'])
            "Object #{show_resource(stmt.object)} not compatible with rangeIncludes (#{ranges.map {|d| d.pname|| d}.join(',')})"
          end
        end
      end

      messages[:class].each {|k, v| messages[:class][k] = v.uniq} if messages[:class]
      messages[:property].each {|k, v| messages[:property][k] = v.uniq} if messages[:property]
      messages
    end

  private

    # Show resource in diagnostic output
    def show_resource(resource)
      if resource.node?
        resource.to_ntriples + '(' +
          self.query({subject: resource, predicate: RDF.type}).
            map {|s| s.object.uri? ? s.object.pname : s.object.to_ntriples}
            .join(',') +
          ')'
      else
        resource.to_ntriples
      end
    end
  end
end