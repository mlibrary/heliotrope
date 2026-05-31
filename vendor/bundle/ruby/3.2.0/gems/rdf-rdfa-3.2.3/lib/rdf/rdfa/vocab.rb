# -*- encoding: utf-8 -*-
# frozen_string_literal: true
# This file generated automatically using rdf vocabulary format from http://www.w3.org/ns/rdfa#
require 'rdf'
module RDF
  # @!parse
  #   # Vocabulary for <http://www.w3.org/ns/rdfa#>
  #   #
  #   # RDFa Vocabulary for Term and Prefix Assignment, and for Processor Graph Reporting
  #   #
  #   # This document describes the RDFa Vocabulary for Term and Prefix Assignment. The Vocabulary is used to modify RDFa 1.1 processing behavior.
  #   # @version $Date: 2013-03-11 07:54:23 $
  #   class RDFA < RDF::Vocabulary
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :PGClass
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :Pattern
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :PrefixOrTermMapping
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :context
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :copy
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :prefix
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :term
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :uri
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :usesVocabulary
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :vocabulary
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :DocumentError
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :Error
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :Info
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :PrefixMapping
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :PrefixRedefinition
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :TermMapping
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :UnresolvedCURIE
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :UnresolvedTerm
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :VocabReferenceError
  #
  #     # @return [RDF::Vocabulary::Term]
  #     attr_reader :Warning
  #
  #   end
  RDFA = Class.new(RDF::Vocabulary("http://www.w3.org/ns/rdfa#")) do

    # Ontology definition
    ontology :"http://www.w3.org/ns/rdfa#",
      "dc:creator": "http://www.ivan-herman.net/foaf#me".freeze,
      "dc:date": "2013-01-18".freeze,
      "dc:description": "This document describes the RDFa Vocabulary for Term and Prefix Assignment. The Vocabulary is used to modify RDFa 1.1 processing behavior.".freeze,
      "dc:publisher": "http://www.w3.org/data#W3C".freeze,
      "dc:title": "RDFa Vocabulary for Term and Prefix Assignment, and for Processor Graph Reporting".freeze,
      isDefinedBy: "http://www.w3.org/TR/rdfa-core/#s_initialcontexts".freeze,
      "owl:versionInfo": "$Date: 2013-03-11 07:54:23 $".freeze,
      type: "owl:Ontology".freeze

    # Class definitions
    term :PGClass,
      "dc:description": "is the top level class of the hierarchy".freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :Pattern,
      "dc:description": "Class to identify an (RDF) resource whose properties are to be copied to another resource".freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :PrefixOrTermMapping,
      "dc:description": "is the top level class for prefix or term mappings".freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]

    # Property definitions
    property :context,
      "dc:description": "provides extra context for the error, eg, http response, an XPointer/XPath information, or simply the URI that created the error".freeze,
      domain: "rdfa:PGClass".freeze,
      type: ["owl:ObjectProperty".freeze, "rdf:Property".freeze]
    property :copy,
      "dc:description": "identifies the resource (i.e., pattern) whose properties and values should be copied to replace the current triple (retaining the subject of the triple).".freeze,
      type: ["owl:ObjectProperty".freeze, "rdf:Property".freeze]
    property :prefix,
      "dc:description": "defines a prefix mapping for a URI; the value is supposed to be a NMTOKEN".freeze,
      domain: "rdfa:PrefixMapping".freeze,
      type: ["owl:DatatypeProperty".freeze, "rdf:Property".freeze]
    property :term,
      "dc:description": "defines a term mapping for a URI; the value is supposed to be a NMTOKEN".freeze,
      domain: "rdfa:TermMapping".freeze,
      type: ["owl:DatatypeProperty".freeze, "rdf:Property".freeze]
    property :uri,
      "dc:description": "defines the URI for either a prefix or a term mapping; the value is supposed to be an absolute URI".freeze,
      domain: "rdfa:PrefixOrTermMapping".freeze,
      type: ["owl:DatatypeProperty".freeze, "rdf:Property".freeze]
    property :usesVocabulary,
      "dc:description": "provides a relationship between the host document and a vocabulary\n\tdefined using the @vocab facility of RDFa1.1".freeze,
      type: ["owl:ObjectProperty".freeze, "rdf:Property".freeze]
    property :vocabulary,
      "dc:description": "defines an absolute URI to be used as a default vocabulary; the value is can be any string; for documentation purposes it is advised to use the string 'true' or 'True'.".freeze,
      type: ["owl:DatatypeProperty".freeze, "rdf:Property".freeze]

    # Extra definitions
    term :DocumentError,
      "dc:description": "error condition; to be used when the document fails to be fully processed as a result of non-conformant host language markup".freeze,
      subClassOf: "rdfa:Error".freeze
    term :Error,
      "dc:description": "is the class for all error conditions".freeze,
      subClassOf: "rdfa:PGClass".freeze
    term :Info,
      "dc:description": "is the class for all informations".freeze,
      subClassOf: "rdfa:PGClass".freeze
    term :PrefixMapping,
      "dc:description": "is the class for prefix mappings".freeze,
      subClassOf: "rdfa:PrefixOrTermMapping".freeze
    term :PrefixRedefinition,
      "dc:description": "warning; to be used when a prefix, either from the initial context or inherited from an ancestor node, is redefined in an element".freeze,
      subClassOf: "rdfa:Warning".freeze
    term :TermMapping,
      "dc:description": "is the class for term mappings".freeze,
      subClassOf: "rdfa:PrefixOrTermMapping".freeze
    term :UnresolvedCURIE,
      "dc:description": "warning; to be used when a CURIE prefix fails to be resolved".freeze,
      subClassOf: "rdfa:Warning".freeze
    term :UnresolvedTerm,
      "dc:description": "warning; to be used when a Term fails to be resolved".freeze,
      subClassOf: "rdfa:Warning".freeze
    term :VocabReferenceError,
      "dc:description": "warning; to be used when the value of a @vocab attribute cannot be dereferenced, hence the vocabulary expansion cannot be completed".freeze,
      subClassOf: "rdfa:Warning".freeze
    term :Warning,
      "dc:description": "is the class for all warnings".freeze,
      subClassOf: "rdfa:PGClass".freeze
  end
end
