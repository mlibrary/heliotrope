# RDF::TriG reader/writer

[TriG][] reader/writer for [RDF.rb][RDF.rb] .

[![Gem Version](https://badge.fury.io/rb/rdf-trig.png)](https://badge.fury.io/rb/rdf-trig)
[![Build Status](https://github.com/ruby-rdf/rdf-trig/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-trig/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-trig/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-trig?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Description
This is a [Ruby][] implementation of a [TriG][] reader and writer for [RDF.rb][].

## Features
RDF::TriG parses [TriG][Trig] into statements or quads. It also serializes to TriG.

Install with `gem install rdf-trig`

* 100% free and unencumbered [public domain](https://unlicense.org/) software.
* Implements a complete parser and serializer for [TriG][].
* Compatible with Ruby 2.x, and JRuby 1.7+.
* Optional streaming writer, to serialize large graphs

## Usage
Instantiate a reader from a local file:

    repo = RDF::Repository.load("etc/doap.trig", :format => :trig)

Define `@base` and `@prefix` definitions, and use for serialization using `:base_uri` an `:prefixes` options.

Canonicalize and validate using `:canonicalize` and `:validate` options.

Write a repository to a file:

    RDF::TriG::Writer.open("etc/test.trig") do |writer|
       writer << repo
    end

Note that reading and writing of graphs is also possible, but as graphs have only a single context,
it is not particularly interesting for TriG.

## RDF-star

Both reader and writer include provisional support for [RDF-star][].

Internally, an `RDF::Statement` is treated as another resource, along with `RDF::URI` and `RDF::Node`, which allows an `RDF::Statement` to have a `#subject` or `#object` which is also an `RDF::Statement`.

Note that this requires the `rdfstar` option to be se.

**Note: This feature is subject to change or elimination as the standards process progresses.**

## Documentation
Full documentation available on [Rubydoc.info][TriG doc].

### Principle Classes
* {RDF::TriG::Format}
* {RDF::TriG::Reader}
* {RDF::TriG::Writer}


## Implementation Notes
This version uses a hand-written parser using the Lexer from the [EBNF][] gem instead of a general [EBNF][] LL(1) parser for faster performance.

The reader uses the [Turtle][Turtle doc] parser. The writer also is based on the Turtle writer.

The syntax is compatible with placing default triples within `{}`, but the writer does not use this for writing triples in the default graph.

There is a new `:stream` option to {RDF::TriG::Writer} which is more efficient for streaming large datasets.
      
## Dependencies

* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [rdf-turtle](https://rubygems.org/gems/rdf-turtle) (~> 3.2)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `RDF::TriG` gem, do:

    % [sudo] gem install rdf-trig

## Mailing List
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributing
* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
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

A copy of the [TriG EBNF][] and derived parser files are included in the repository, which are not covered under the UNLICENSE. These files are covered via the [W3C Document License](https://www.w3.org/Consortium/Legal/2002/copyright-documents-20021231).

[Ruby]:         https://ruby-lang.org/
[RDF]:          https://www.w3.org/RDF/
[YARD]:         https://yardoc.org/
[YARD-GS]:      https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[RDF.rb]:       https://rubydoc.info/github/ruby-rdf/rdf/master/frames
[Backports]:    https://rubygems.org/gems/backports
[RDF-star]:         https://w3c.github.io/rdf-star/rdf-star-cg-spec.html
[TriG]:         https://www.w3.org/TR/trig/
[TriG doc]:     https://rubydoc.info/github/ruby-rdf/rdf-trig/master/file/README.markdown
[TriG EBNF]:    https://dvcs.w3.org/hg/rdf/raw-file/default/trig/trig.bnf
[Turtle doc]:   https://rubydoc.info/github/ruby-rdf/rdf-turtle/master/file/README.markdown
