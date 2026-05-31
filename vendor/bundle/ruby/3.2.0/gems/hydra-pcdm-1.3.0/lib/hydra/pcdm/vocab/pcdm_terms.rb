# -*- encoding: utf-8 -*-
# This file generated automatically using vocab-fetch from https://raw.githubusercontent.com/duraspace/pcdm/master/models.rdf
require 'rdf'
module Hydra::PCDM
  module Vocab
    class PCDMTerms < RDF::StrictVocabulary('http://pcdm.org/models#')
      # Class definitions
      term :AdministrativeSet,
           comment: %(
             An Administrative Set is a grouping of resources that an administrative unit is ultimately
             responsible for managing. The set itself helps to manage the items within it. An Object
             or Collection may be contained by only one AdministrativeSet.
           ).freeze,
           label: 'Administrative Set'.freeze,
           'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
           subClassOf: 'http://www.w3.org/ns/ldp#Container'.freeze,
           type: 'rdfs:Class'.freeze
      term :Collection,
           comment: %(
             A Collection is a group of resources. Collections have descriptive metadata, access metadata,
             and may links to works and/or collections. By default, member works and collections are an
             unordered set, but can be ordered using the ORE Proxy class.
           ).freeze,
           label: 'Collection'.freeze,
           'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
           subClassOf: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
           type: 'rdfs:Class'.freeze
      term :File,
           comment: %(
             A File is a sequence of binary data and is described by some accompanying metadata.
             The metadata typically includes at least basic technical metadata \(size, content type,
             modification date, etc.\), but can also include properties related to preservation,
             digitization process, provenance, etc. Files MUST be contained by exactly one Object.
           ).freeze,
           label: 'File'.freeze,
           'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
           type: 'rdfs:Class'.freeze
      term :Object,
           comment: %(
             An Object is an intellectual entity, sometimes called a "work", "digital object", etc.
             Objects have descriptive metadata, access metadata, may contain files and other Objects as
             member "components". Each level of a work is therefore represented by an Object instance,
             and is capable of standing on its own, being linked to from Collections and other Objects.
             Member Objects can be ordered using the ORE Proxy class.
           ).freeze,
           label: 'Object'.freeze,
           'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
           subClassOf: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
           type: 'rdfs:Class'.freeze

      # Property definitions
      property :fileOf,
               comment: %(Links from a File to its containing Object.).freeze,
               domain: 'http://pcdm.org/models#File'.freeze,
               label: 'is file of'.freeze,
               range: 'http://pcdm.org/models#Object'.freeze,
               'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
               subPropertyOf: 'http://www.openarchives.org/ore/terms/isAggregatedBy'.freeze,
               type: 'rdf:Property'.freeze
      property :hasFile,
               comment: %(Links to a File contained by this Object.).freeze,
               domain: 'http://pcdm.org/models#Object'.freeze,
               label: 'has file'.freeze,
               range: 'http://pcdm.org/models#File'.freeze,
               'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
               subPropertyOf: 'http://www.openarchives.org/ore/terms/aggregates'.freeze,
               type: 'rdf:Property'.freeze
      property :hasMember,
               comment: %(Links to a related Object. Typically used to link to component parts, such as a book linking to a page.).freeze,
               domain: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
               label: 'has member'.freeze,
               range: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
               'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
               subPropertyOf: 'http://www.openarchives.org/ore/terms/aggregates'.freeze,
               type: 'rdf:Property'.freeze
      property :hasRelatedObject,
               comment: %(Links to a related Object that is not a component part, such as an object representing a donor agreement or policies that govern the resource.).freeze,
               domain: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
               label: 'has related object'.freeze,
               range: 'http://pcdm.org/models#Object'.freeze,
               'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
               subPropertyOf: 'http://www.openarchives.org/ore/terms/aggregates'.freeze,
               type: 'rdf:Property'.freeze
      property :memberOf,
               comment: %(Links from an Object or Collection to a containing Object or Collection.).freeze,
               domain: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
               label: 'is member of'.freeze,
               range: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
               'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
               subPropertyOf: 'http://www.openarchives.org/ore/terms/isAggregatedBy'.freeze,
               type: 'rdf:Property'.freeze
      property :relatedObjectOf,
               comment: %(Links from an Object to a Object or Collection that it is related to.).freeze,
               domain: 'http://pcdm.org/models#Object'.freeze,
               label: 'is related object of'.freeze,
               range: 'http://www.openarchives.org/ore/terms/Aggregation'.freeze,
               'rdfs:isDefinedBy' => %(http://pcdm.org/models#).freeze,
               subPropertyOf: 'http://www.openarchives.org/ore/terms/isAggregatedBy'.freeze,
               type: 'rdf:Property'.freeze

      # Extra definitions
      term :"",
           comment: %(Ontology for the Portland Common Data Model, intended to underlie a wide array of repository and DAMS applications.).freeze,
           'dc:modified' => %(2015-03-16).freeze,
           'dc:publisher' => %(http://www.duraspace.org/).freeze,
           'dc:title' => %(Portland Common Data Model).freeze,
           label: ''.freeze,
           'owl:versionInfo' => %(2015/03/16).freeze,
           'rdfs:seeAlso' => %(https://github.com/duraspace/pcdm/wiki).freeze
    end
  end
end
