# coding: utf-8

module RDF::Reasoner
  ##
  # Rules for generating OWL entailment triples
  #
  # Extends `RDF::URI` and `RDF::Statement` with specific entailment capabilities
  module OWL
    ##
    # @return [RDF::Util::Cache]
    # @private
    def equivalentClass_cache
      @@subPropertyOf_cache ||= {}
    end
    ##
    # @return [RDF::Util::Cache]
    # @private
    def equivalentProperty_cache
      @@equivalentProperty_cache ||= {}
    end


    ##
    # For a Term: yield or return inferred equivalentClass relationships
    # For a Statement: if predicate is `rdf:types`, yield or return inferred statements having a equivalentClass relationship to the type of this statement
    # @private
    def _entail_equivalentClass
      case self
      when RDF::URI, RDF::Node
        unless class?
          yield self if block_given?
          return Array(self)
        end

        # Initialize @equivalentClass_cache by iterating over all defined property terms having an `owl:equivalentClass` attribute and adding the source class as an equivalent of the destination class
        if equivalentClass_cache.empty?
          RDF::Vocabulary.each do |v|
            v.each do |term|
              term.equivalentClass.each do |equiv|
                (equivalentClass_cache[equiv] ||= []) << term
              end if term.class?
            end
          end
        end
        terms = (self.equivalentClass + Array(equivalentClass_cache[self])).uniq
        terms.each {|t| yield t} if block_given?
        terms
      when RDF::Statement
        statements = []
        if self.predicate == RDF.type
          if term = (RDF::Vocabulary.find_term(self.object) rescue nil)
            term._entail_equivalentClass do |t|
              statements << RDF::Statement(**self.to_h.merge(object: t, inferred: true))
            end
          end
        end
        statements.each {|s| yield s} if block_given?
        statements
      else []
      end
    end

    ##
    # For a Term: yield or return return inferred equivalentProperty relationships
    # For a Statement: yield or return inferred statements having a equivalentProperty relationship to predicate of this statement
    # @private
    def _entail_equivalentProperty
      case self
      when RDF::URI, RDF::Node
        unless property?
          yield self if block_given?
          return Array(self)
        end

        # Initialize equivalentProperty_cache by iterating over all defined property terms having an `owl:equivalentProperty` attribute and adding the source class as an equivalent of the destination class
        if equivalentProperty_cache.empty?
          RDF::Vocabulary.each do |v|
            v.each do |term|
              term.equivalentProperty.each do |equiv|
                (equivalentProperty_cache[equiv] ||= []) << term
              end if term.property?
            end
          end
        end
        terms = (self.equivalentProperty + Array(equivalentProperty_cache[self])).uniq
        terms.each {|t| yield t} if block_given?
        terms
      when RDF::Statement
        statements = []
        if term = (RDF::Vocabulary.find_term(self.predicate) rescue nil)
          term._entail_equivalentProperty do |t|
            statements << RDF::Statement(**self.to_h.merge(predicate: t, inferred: true))
          end
        end
        statements.each {|s| yield s} if block_given?
        statements
      else []
      end
    end

    def self.included(mod)
      mod.add_entailment :equivalentClass, :_entail_equivalentClass
      mod.add_entailment :equivalentProperty, :_entail_equivalentProperty
    end
  end

  # Extend URI with these methods
  ::RDF::URI.send(:include, OWL)

  # Extend Statement with these methods
  ::RDF::Statement.send(:include, OWL)

  # Extend Enumerable with these methods
  ::RDF::Enumerable.send(:include, OWL)

  # Extend Mutable with these methods
  ::RDF::Mutable.send(:include, OWL)
end