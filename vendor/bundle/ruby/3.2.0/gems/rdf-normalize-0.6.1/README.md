# RDF::Normalize
RDF Graph normalizer for [RDF.rb][RDF.rb].

[![Gem Version](https://badge.fury.io/rb/rdf-normalize.svg)](https://badge.fury.io/rb/rdf-normalize)
[![Build Status](https://github.com/ruby-rdf/rdf-normalize/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-normalize/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-normalize/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-normalize?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Description
This is a [Ruby][] implementation of a [RDF Dataset Canonicalization][] for [RDF.rb][].

## Features
RDF::Normalize generates normalized [N-Quads][] output for an RDF Dataset using the algorithm
defined in [RDF Normalize][]. It also implements an RDF Writer interface, which can be used
to serialize normalized statements.

Algorithms implemented:

* [URGNA2012](https://www.w3.org/TR/rdf-canon/#dfn-urgna2012)
* [RDFC-1.0](https://www.w3.org/TR/rdf-canon/#dfn-rdfc-1-0)

Install with `gem install rdf-normalize`

* 100% free and unencumbered [public domain](https://unlicense.org/) software.
* Compatible with  Ruby >= 2.6.

## Usage

## Documentation

Full documentation available on [GitHub][Normalize doc]

## Examples

### Returning normalized N-Quads

    require 'rdf/normalize'
    require 'rdf/turtle'
    g = RDF::Graph.load("etc/doap.ttl")
    puts g.dump(:normalize)

### Principle Classes
* {RDF::Normalize}
  * {RDF::Normalize::Base}
  * {RDF::Normalize::Format}
  * {RDF::Normalize::Writer}
  * {RDF::Normalize::URGNA2012}
  * {RDF::Normalize::RDFC10}

## Dependencies

* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `RDF::Normalize` gem, do:

    % [sudo] gem install rdf-normalize

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
see <https://unlicense.org/> or the accompanying {file:LICENSE} file.

[Ruby]:         https://ruby-lang.org/
[RDF]:          https://www.w3.org/RDF/
[YARD]:         https://yardoc.org/
[YARD-GS]:      https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[RDF.rb]:       https://ruby-rdf.github.io/rdf-normalize
[N-Triples]:    https://www.w3.org/TR/rdf-testcases/#ntriples
[RDF Dataset Canonicalization]: https://www.w3.org/TR/rdf-canon/
[Normalize doc]: https://ruby-rdf.github.io/rdf-normalize/
