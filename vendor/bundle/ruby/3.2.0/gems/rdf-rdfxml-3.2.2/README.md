# RDF::RDFXML reader/writer 

[RDF/XML][] reader/writer for [RDF.rb][].

[![Gem Version](https://badge.fury.io/rb/rdf-rdfxml.svg)](https://badge.fury.io/rb/rdf-rdfxml)
[![Build Status](https://github.com/ruby-rdf/rdf-rdfxml/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-rdfxml/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-rdfxml/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-rdfxml?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## DESCRIPTION

RDF::RDFXML is an [RDF/XML][RDF/XML] reader/writer for [Ruby][] using the [RDF.rb][RDF.rb] library suite.

## FEATURES
RDF::RDFXML parses [RDF/XML][] into statements or triples and serializes triples, statements or graphs. It also serializes graphs to [RDF/XML][].

Fully compliant [RDF/XML][] parser and serializer.

Install with `gem install rdf-rdfxml`

* 100% free and unencumbered [public domain](https://unlicense.org/) software.
* Implements a complete parser for [RDF/XML][].
* Compatible with Ruby >= 2.6.

## Usage:
Instantiate a parser and parse source, specifying type and base-URL

    RDF::RDFXML::Reader.open("./etc/doap.xml") do |reader|
      reader.each_statement do |statement|
        puts statement.inspect
      end
    end

Define `xml:base` and `xmlns` definitions, and use for serialization using `:base_uri` an `:prefixes` options.

Canonicalize and validate using `:canonicalize` and `:validate` options.

Write a graph to a file:

    RDF::RDFXML::Writer.open("etc/test.ttl") do |writer|
       writer << graph
    end

## Dependencies
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [Builder](https://rubygems.org/gems/builder) (~>- 3.2)
* Soft dependency on [Nokogiri](https://rubygems.org/gems/nokogiri) (>= 1.13)

## Documentation
Full documentation available on [Rubydoc.info][RDF/XML doc])

### Principle Classes
* {RDF::RDFXML}
* {RDF::RDFXML::Format}
* {RDF::RDFXML::Reader}
* {RDF::RDFXML::Writer}

## Resources
* [RDF.rb][RDF.rb]
* [RDF/XML][RDF/XML]
* [Distiller](http://rdf.greggkellogg.net)
* [Documentation][RDF/XML doc]
* [RDF Tests](https://www.w3.org/2000/10/rdf-tests/rdfcore/allTestCases.html)

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributors
* [Nicholas Humfrey](https://github.com/njh) - <http://njh.me/>

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

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

## FEEDBACK

* gregg@greggkellogg.net
* <https://rubygems.org/rdf-rdfxml>
* <https://github.com/ruby-rdf/rdf-rdfxml>
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

[Ruby]:         https://ruby-lang.org/
[RDF]:          https://www.w3.org/RDF/
[RDF.rb]:       https://rubygems.org/gems/rdf
[RDF/XML]:      http://www.w3.org/TR/rdf-syntax-grammar/ "RDF/XML Syntax Specification"
[YARD]:         https://yardoc.org/
[YARD-GS]:      https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[RDF/XML doc]:  https://ruby-rdf.github.io/rdf-rdfxml/master/frames
[RDF-star]:         https://w3c.github.io/rdf-star/rdf-star-cg-spec.html
