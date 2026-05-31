# ShEx: Shape Expression language for Ruby

This is a pure-Ruby library for working with the [Shape Expressions Language][ShExSpec] to validate the shape of [RDF][] graphs.

[![Gem Version](https://badge.fury.io/rb/shex.png)](https://badge.fury.io/rb/shex)
[![Build Status](https://github.com/ruby-rdf/shex/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/shex/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/shex/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/shex?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)
[![DOI](https://zenodo.org/badge/74419330.svg)](https://zenodo.org/badge/latestdoi/74419330)

## Features

* 100% pure Ruby with minimal dependencies and no bloat.
* Fully compatible with [ShEx][ShExSpec] specifications.
* 100% free and unencumbered [public domain](https://unlicense.org/) software.

## Description

The ShEx gem implements a [ShEx][ShExSpec] Shape Expression engine version 2.0.

* `ShEx::Parser` parses ShExC and ShExJ formatted documents generating executable operators which can be serialized as [S-Expressions][].
* `ShEx::Algebra` executes operators against Any `RDF::Graph`, including compliant [RDF.rb][].
* [Implementation Report](file.earl.html)

## Examples
### Validating a node using ShExC

    require 'rdf/turtle'
    require 'shex'

    shexc = %(
      PREFIX doap:  <http://usefulinc.com/ns/doap#>
      PREFIX dc:    <http://purl.org/dc/terms/>
      PREFIX ex:    <http://example.com/>

      ex:TestShape EXTRA a {
        a [doap:Project];
        ( doap:name Literal;
          doap:description Literal
        | dc:title Literal;
          dc:description Literal)+;
        doap:category    IRI*;
        doap:developer   IRI+;
        doap:implements [<http://shex.io/shex-semantics/>]
      }
    )
    graph = RDF::Graph.load("etc/doap.ttl")
    schema = ShEx.parse(shexc)
    map = {
      RDF::URI("https://rubygems.org/gems/shex") => RDF::URI("http://example.com/TestShape")
    }
    schema.satisfies?(graph, map)
    # => true
### Validating a node using ShExJ

    require 'rubygems'
    require 'rdf/turtle'
    require 'shex'

    shexj = %({
      "@context": "http://www.w3.org/ns/shex.jsonld",
      "type": "Schema",
      "shapes": [{
        "id": "http://example.com/TestShape",
        "type": "Shape",
        "extra": ["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"],
        "expression": {
          "type": "EachOf",
          "expressions": [{
            "type": "TripleConstraint",
            "predicate": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
            "valueExpr": {
              "type": "NodeConstraint",
              "values": ["http://usefulinc.com/ns/doap#Project"]
            }
          }, {
            "type": "OneOf",
            "expressions": [{
                "type": "EachOf",
                "expressions": [{
                  "type": "TripleConstraint",
                  "predicate": "http://usefulinc.com/ns/doap#name",
                  "valueExpr": {
                    "type": "NodeConstraint",
                    "nodeKind": "literal"
                  }
                }, {
                  "type": "TripleConstraint",
                  "predicate": "http://usefulinc.com/ns/doap#description",
                  "valueExpr": {
                    "type": "NodeConstraint",
                    "nodeKind": "literal"
                  }
                }]
              }, {
                "type": "EachOf",
                "expressions": [{
                  "type": "TripleConstraint",
                  "predicate": "http://purl.org/dc/terms/title",
                  "valueExpr": {
                    "type": "NodeConstraint",
                    "nodeKind": "literal"
                  }
                }, {
                  "type": "TripleConstraint",
                  "predicate": "http://purl.org/dc/terms/description",
                  "valueExpr": {
                    "type": "NodeConstraint",
                    "nodeKind": "literal"
                  }
                }]
              }],
              "min": 1,
              "max": -1
            }, {
              "type": "TripleConstraint",
              "predicate": "http://usefulinc.com/ns/doap#category",
              "valueExpr": {
                "type": "NodeConstraint",
                "nodeKind": "iri"
              },
              "min": 0,
              "max": -1
            }, {
              "type": "TripleConstraint",
              "predicate": "http://usefulinc.com/ns/doap#developer",
              "valueExpr": {
                "type": "NodeConstraint",
                "nodeKind": "iri"
              },
              "min": 1,
              "max": -1
            }, {
              "type": "TripleConstraint",
              "predicate": "http://usefulinc.com/ns/doap#implements",
              "valueExpr": {
                "type": "NodeConstraint",
                "values": [
                  "http://shex.io/shex-semantics/"
                ]
              }
            }
          ]
        }
      }
    ]})
    graph = RDF::Graph.load("etc/doap.ttl")
    schema = ShEx.parse(shexj, format: :shexj)
    map = {
      RDF::URI("https://rubygems.org/gems/shex") => RDF::URI("http://example.com/TestShape")
    }
    schema.satisfies?(graph, map)
    # => true

## Extensions
ShEx has an extension mechanism using [Semantic Actions](http://shex.io/shex-semantics/#semantic-actions). Extensions may be implemented in Ruby ShEx by sub-classing {ShEx::Extension} and implementing {ShEx::Extension#visit} and possibly {ShEx::Extension#initialize}, {ShEx::Extension#enter}, {ShEx::Extension#exit}, and {ShEx::Extension#close}. The `#visit` method will be called as part of the `#satisfies?` operation.

    require 'shex'
    class ShEx::Test < ShEx::Extension("http://shex.io/extensions/Test/")
      # (see ShEx::Extension#initialize)
      def initialize(schema: nil, logger: nil, depth: 0, **options)
        ...
      end

      # (see ShEx::Extension#visit)
      def visit(code: nil, matched: nil, expression: nil, depth: 0, **options)
        ...
      end
    end

The `#enter` method will be called on any {ShEx::Algebra::TripleExpression} that includes a {ShEx::Algebra::SemAct} referencing the extension, while the `#exit` method will be called on exit, even if not satisfied.

The `#initialize` method is called when {ShEx::Algebra::Schema#execute} starts and `#close` called on exit, even if not satisfied.

To make sure your extension is found, make sure to require it before the shape is executed.

## Command Line
When the `linkeddata` gem is installed, RDF.rb includes a `rdf` executable which acts as a wrapper to perform a number of different
operations on RDF files, including ShEx. The commands specific to ShEx is 

* `shex`: Validate repository given shape

Using this command requires either a `shex-input` where the ShEx schema is URI encoded, or `shex`, which references a URI or file path to the schema. Other required options are `shape` and `focus`.

Example usage:

    rdf shex https://raw.githubusercontent.com/ruby-rdf/shex/develop/etc/doap.ttl \
      --schema https://raw.githubusercontent.com/ruby-rdf/shex/develop/etc/doap.shex \
      --focus https://rubygems.org/gems/shex

## Documentation

<https://ruby-rdf.github.io/shex>


## Implementation Notes
The ShExC parser uses the [EBNF][] gem to generate a [PEG][] parser.

The parser uses the executable [S-Expressions][] generated from the EBNF ShExC grammar to create a set of executable {ShEx::Algebra} Operators which are directly executed to perform shape validation.

## Dependencies

* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [SPARQL gem](https://rubygems.org/gems/sparql) (~> 3.1)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of RDF.rb, do:

    % [sudo] gem install shex

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/shex.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget https://github.com/ruby-rdf/shex/tarball/master

## Resources

* <https://ruby-rdf.github.io/shex>
* <https://github.com/ruby-rdf/shex>
* <https://rubygems.org/gems/shex>

## Mailing List

* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author

* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributing

This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
  Before committing, run `git diff --check` to make sure of this.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec` or `VERSION` files. If you need to change them,
  do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the
  corresponding list in the the `README`. Alphabetical order applies.
* Don't touch the `AUTHORS` file. If your contributions are significant
  enough, be assured we will eventually add you in there.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:LICENSE} file.

[ShExSpec]:     http://shex.io/shex-semantics-20170713/
[RDF]:          https://www.w3.org/RDF/
[RDF.rb]:       https://ruby-rdf.github.io/rdf
[EBNF]:         https://rubygems.org/gems/ebnf
[YARD]:         https://yardoc.org/
[YARD-GS]:      https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[PEG]:          https://en.wikipedia.org/wiki/Parsing_expression_grammar "Parsing Expression Grammar"
[S-Expression]: https://en.wikipedia.org/wiki/S-expression
