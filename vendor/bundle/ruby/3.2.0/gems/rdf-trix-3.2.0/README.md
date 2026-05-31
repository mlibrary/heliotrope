# TriX Support for RDF.rb

[TriX][] reader/writer for [RDF.rb][RDF.rb] .

[![Gem Version](https://badge.fury.io/rb/rdf-trix.png)](https://badge.fury.io/rb/rdf-trix)
[![Build Status](https://github.com/ruby-rdf/rdf-trix/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-trix/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-trix/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-trix?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Description
This is a [Ruby][] implementation of a [TriX][] reader and writer for [RDF.rb][]. TriX is an XML-based RDF serialization format developed by HP Labs and Nokia.

## Features
RDF::TriX parses [TriX][] into statements or quads. It also serializes to TriX.

Install with `gem install rdf-trix`

* 100% free and unencumbered [public domain](https://unlicense.org/) software.
* Implements a complete parser and serializer for [TriX][].
* Compatible with Ruby >= 2.6, and JRuby 9+.

### Support for xml:base

The TriX reader natively supports `xml:base` in the top-level element without the need for an XSLT. This allows values of a `uri` element to be relative URIs and resolved against that base. The base can also be specified as an option to the reader.

For example:

    <TriX xmlns="http://www.w3.org/2004/03/trix/trix-1/"
          xml:base="http://example.org/">
      <graph>
        <uri>graph1</uri>
        <triple>
          <uri>Bob</uri>
          <uri>wife</uri>
          <uri>Mary</uri>
        </triple>
        <triple>
          <uri>Bob</uri>
          <uri>name</uri>
          <plainLiteral>Bob</plainLiteral>
        </triple>
        <triple>
          <uri>Mary</uri>
          <uri>age</uri>
          <typedLiteral datatype="http://www.w3.org/2001/XMLSchema#integer">32</typedLiteral>
        </triple>
     </graph>
    </TriX>

### RDF-star

Both reader and writer include provisional support for [RDF-star][].

Internally, an `RDF::Statement` is treated as another resource, along with `RDF::URI` and `RDF::Node`, which allows an `RDF::Statement` to have a `#subject` or `#object` which is also an `RDF::Statement`.

RDF-star is supported by allowing a `triple` element to contain another `triple` as either or both the _subject_ or _object_.

Note that this requires the `rdfstar` option to be se.

**Note: This feature is subject to change or elimination as the standards process progresses.**

For example:

    <TriX xmlns="http://www.w3.org/2004/03/trix/trix-1/">
      <graph>
        <triple>
          <triple>
            <uri>http://example/s1</uri>
            <uri>http://example/p1</uri>
            <uri>http://example/o1</uri>
          </triple>
          <uri>http://example/p</uri>
          <uri>http://example/o</uri>
        </triple>
      </graph>
    </TriX>

## Usage
Instantiate a reader from a local file:

    repo = RDF::Repository.load("etc/doap.trix", :format => :trix)

Define `@base` and `@prefix` definitions, and use for serialization using `:base_uri` an `:prefixes` options.

Canonicalize and validate using `:canonicalize` and `:validate` options.

Write a repository to a file:

    RDF::TriX::Writer.open("etc/test.trix") do |writer|
       writer << repo
    end

## Dependencies
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.1)
* Soft dependency on [Nokogiri](https://rubygems.org/gems/nokogiri) (>= 1.10)
* Soft dependency on [Libxml-Ruby](https://rubygems.org/gems/libxml-ruby) (>= 3.0)

## Documentation

* {RDF::TriX}
  * {RDF::TriX::Format}
  * {RDF::TriX::Reader}
  * {RDF::TriX::Writer}

## Dependencies

* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
  [Nokogiri](https://rubygems.org/gems/nokogiri) (~> 1.12)
  [LibXML](https://rubygems.org/gems/libxml) (>= 3.2)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `RDF::TriX` gem, do:

    % [sudo] gem install rdf-trix

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/rdf-trix.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget https://github.com/ruby-rdf/rdf-trix/tarball/master

## Mailing List

* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Authors

* [Arto Bendiken](https://github.com/artob) - <https://ar.to/>
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

# Contributors

Refer to the accompanying {file:CREDITS} file.

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
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[RDF.rb]:   https://rubygems.org/gems/rdf/
[TriX]:     https://www.hpl.hp.com/techreports/2004/HPL-2004-56.html
[PDD]:              https://unlicense.org/#unlicensing-contributions
[RDF-star]:         https://w3c.github.io/rdf-star/rdf-star-cg-spec.html
