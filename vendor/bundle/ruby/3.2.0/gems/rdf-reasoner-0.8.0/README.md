# RDF::Reasoner

A partial RDFS/OWL/schema.org reasoner for [RDF.rb][].

[![Gem Version](https://badge.fury.io/rb/rdf-reasoner.png)](https://badge.fury.io/rb/rdf-reasoner)
[![Build Status](https://github.com/ruby-rdf/rdf-reasoner/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-reasoner/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-reasoner/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-reasoner?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Description

Reasons over RDFS/OWL vocabularies and schema.org to generate statements which are entailed based on base RDFS/OWL rules along with vocabulary information. It can also be used to ask specific questions, such as if a given object is consistent with the vocabulary ruleset. This can be used to implement [SPARQL Entailment][] Regimes and [RDF Schema][] entailment.

## Features

* Entail `rdfs:subClassOf` generating an array of terms which are ancestors of the subject.
* Entail `rdfs:subPropertyOf` generating an array of terms which are ancestors of the subject.
* Entail `rdfs:domain` and `rdfs:range` adding `rdf:type` assertions on the subject or object.
* Inverse `rdfs:subClassOf` entailment, to find descendant classes of the subject term.
* Inverse `rdfs:subPropertyOf` entailment, to find descendant properties of the subject term.
* Entail `owl:equivalentClass` generating an array of terms equivalent to the subject.
* Entail `owl:equivalentProperty` generating an array of terms equivalent to the subject.
* `domainCompatible?` determines if a particular resource is compatible with the domain definition of a given predicate, based on the intersection of entailed subclasses with the property domain.
* `rangeCompatible?` determines if a particular resource is compatible with the range definition of a given predicate, based on the intersection of entailed subclasses or literal types with the property domain.
* adds `entail` and `lint` commands to the `rdf` command line interface

Domain and Range entailment include specific rules for schema.org vocabularies.

* A plain literal is an acceptable value for any property.
* If `resource` is of type `schema:Role`, `resource` is domain acceptable if any other resource references `resource` using the same property.
* If `resource` is of type `schema:Role`, it is range acceptable if it has the same property with an acceptable value.
* If `resource` is of type `rdf:List` (must be previously entailed), it is range acceptable if all members of the list are otherwise range acceptable on the same property.

### Limiting vocabularies used for reasoning

As loading vocabularies can dominate processing time, the `RDF::Vocabulary.limit_vocabs` method can be used to set a specific set of vocabularies over which to reason. For example:

    RDF::Vocabulary.limit_vocabs(:rdf, :rdf, :schema)

will limit the vocabularies which are returned from `RDF::Vocabulary.each`, which is used for reasoning and other operations over vocabularies and terms.
    
## Examples
### Determine super-classes of a class

    require 'rdf/reasoner'

    RDF::Reasoner.apply(:rdfs)
    term = RDF::Vocabulary.find_term("http://xmlns.com/foaf/0.1/Person")
    term.entail(:subClassOf)
      # => [
        foaf:Agent,
        http://www.w3.org/2000/10/swap/pim/contact#Person,
        geo:SpatialThing,
        foaf:Person
      ]

### Determine sub-classes of a class

    require 'rdf/reasoner'

    RDF::Reasoner.apply(:rdfs)
    term = RDF::Vocab::FOAF.Person
    term.entail(:subClass) # => [foaf:Person, mo:SoloMusicArtist]

### Determine if a resource is compatible with the domains of a property

    require 'rdf/reasoner'
    require 'rdf/turtle'

    RDF::Reasoner.apply(:rdfs)
    graph = RDF::Graph.load("etc/doap.ttl")
    subj = RDF::URI("https://rubygems.org/gems/rdf-reasoner")
    RDF::Vocab::DOAP.name.domain_compatible?(subj, graph) # => true

### Determine if a resource is compatible with the ranges of a property

    require 'rdf/reasoner'
    require 'rdf/turtle'

    RDF::Reasoner.apply(:rdfs)
    graph = RDF::Graph.load("etc/doap.ttl")
    obj = RDF::Literal(Date.new)
    RDF::Vocab::DOAP.created.range_compatible?(obj, graph) # => true

### Perform equivalentClass entailment on a graph

    require 'rdf/reasoner'
    require 'rdf/turtle'

    RDF::Reasoner.apply(:owl)
    graph = RDF::Graph.load("etc/doap.ttl")
    graph.entail!(:equivalentClass)

### Yield all entailed statements for all entailment methods

    require 'rdf/reasoner'
    require 'rdf/turtle'

    RDF::Reasoner.apply(:rdfs, :owl)
    graph = RDF::Graph.load("etc/doap.ttl")
    graph.enum_statement.entail.count # >= graph.enum_statement.count

### Lint an expanded graph

    require 'rdf/reasoner'
    require 'rdf/turtle'

    RDF::Reasoner.apply(:rdfs, :owl)
    graph = RDF::Graph.load("etc/doap.ttl")
    graph.entail!
    messages = graph.lint
    messages.each do |kind, term_messages|
      term_messages.each do |term, messages|
        options[:output].puts "#{kind}  #{term}"
        messages.each {|m| options[:output].puts "  #{m}"}
      end
    end

## Command-Line interface
The `rdf` command-line interface is extended with `entail` and `lint` commands. `Entail` can be used in combination, with `serialize` to generate an output graph representation including entailed triples.

## Dependencies

* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)

## Mailing List

* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Authors

* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributing

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
  Before committing, run `git diff --check` to make sure of this.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Ruby]:             https://ruby-lang.org/
[RDF]:              https://www.w3.org/RDF/
[YARD]:             https://yardoc.org/
[YARD-GS]:          https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[SPARQL]:           https://en.wikipedia.org/wiki/SPARQL
[SPARQL Query]:     https://www.w3.org/TR/2013/REC-sparql11-query-20130321/
[SPARQL Entailment]:https://www.w3.org/TR/sparql11-entailment/
[RDF 1.1]:          https://www.w3.org/TR/rdf11-concepts
[RDF.rb]:           https://www.rubydoc.info/github/ruby-rdf/rdf/
[RDF Schema]:       https://www.w3.org/TR/rdf-schema/
[Rack]:             https://rack.github.io/
