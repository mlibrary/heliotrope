# LD Patch for RDF.rb

This is a [Ruby][] implementation of [LD Patch][] for [RDF.rb][].

[![Gem Version](https://badge.fury.io/rb/ld-patch.svg)](https://badge.fury.io/rb/ld-patch)
[![Build Status](https://github.com/ruby-rdf/ld-patch/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/ld-patch/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/ld-patch/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/ld-patch?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Description

This gem implements the [LD Patch][] specification with a couple of changes and/or limitations:

* The `INDEX` terminal was replaced by `INTEGER`. Having two terminals matching the same token strings causes a conflict. As a result, a _slice_ may contain positive integers, as well as unsigned and negative-integers.
* The _graph_ rule is changed to the following:

      [18]    graph           ::=     triples  ('.' triples?)*

  This is necessary as the specified production is not context-free. As a result, it is possible for a graph to contain multiple trailing "`.`".

[LD Patch][] is useful inside a Rack container where it can respond to `POST` messages to affect the modification of a _target graph_ identified using the URL of the `POST`.

## Features

* 100% free and unencumbered [public domain](http://unlicense.org/) software.
* Complete [Linked Data Patch Format][LD Patch] parsing and execution
* Implementation Report: {file:etc/earl.html EARL}
* Compatible with Ruby >= 2.6.

## Documentation
Full documentation available on [Rubydoc.info][LD-Patch doc]

## Examples

    require 'rubygems'
    require 'ld/patch'

### Example Patch

    queryable = RDF::Repository.load("etc/doap.ttl")
    patch = %(
      @prefix doap: <http://usefulinc.com/ns/doap#> .
      @prefix earl: <http://www.w3.org/ns/earl#> .
      @prefix foaf: <http://xmlns.com/foaf/0.1/> .

      Delete { <> a earl:TestSubject, earl:Software } .
      Add {
        <http://greggkellogg.net/foaf#me> a foaf:Person;
          foaf:name "Gregg Kellogg"
      } .
      Bind ?ruby <> / doap:programming-language .
      Cut ?ruby .
    )
    operator = LD::Patch.parse(patch, base_uri: "https://rubygems.org/gems/ld-patch")
    operator.execute(queryable) # alternatively queryable.query(operator)

## Command Line
When the `linkeddata` gem is installed, RDF.rb includes a `rdf` executable which acts as a wrapper to perform a number of different
operations on RDF files, including LD::Patch, which is used as a stream command and must be followed by serialize to see the results. The commands specific to LD::Patch is 

* `ld-patch`: Patch the current graph using a patch file

Using this command requires either a `patch-input` where the patch is URI encoded, or `patch-file`, which references a URI or file path to the patch. 
Example usage:

    rdf patch serialize https://raw.githubusercontent.com/ruby-rdf/ld-patch/develop/etc/doap.ttl \
      --patch-input Add%20%7B%20%3Chttp://example.org/s2%3E%20%3Chttp://example.org/p2%3E%20%3Chttp://example.org/o2%3E%20%7D%20. \
      --output-format ttl

## Implementation Notes
The reader uses the [EBNF][] gem to generate first, follow and branch tables, and uses the `Parser` and `Lexer` modules to implement the LD Patch parser.

The parser takes branch and follow tables generated from the [LD Patch Grammar](file.ld-patch.html) described in the [specification][LD Patch]. Branch and Follow tables are specified in the generated {LD::Patch::Meta}.

## Dependencies

* [Ruby](http://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [EBNF][] (~> 1.3)
* [SPARQL][] (~> 3.2)
* [SXP][] (~> 1.2)
* [RDF::XSD][] (~> 3.2)

## Mailing List
* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <http://greggkellogg.net/>

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License
This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:LICENSE} file.

A copy of the [LD Patch EBNF](file:etc/ld-patch.ebnf) and derived parser files are included in the repository, which are not covered under the UNLICENSE. These files are covered via the [W3C Document License](http://www.w3.org/Consortium/Legal/2002/copyright-documents-20021231).

[Ruby]:           http://ruby-lang.org/
[RDF]:            http://www.w3.org/RDF/
[YARD]:           http://yardoc.org/
[YARD-GS]:        http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[RDF.rb]:         https://rubygems.org/gems/rdf
[RDF::XSD]:       https://rubygems.org/gems/rdf-xsd
[EBNF]:           https://rubygems.org/gems/ebnf
[SPARQL]:         https://rubygems.org/gems/sparql
[Linked Data]:    https://rubygems.org/gems/linkeddata
[SSE]:            http://openjena.org/wiki/SSE
[SXP]:            https://dryruby.github.io/sxp
[LD Patch]:       http://www.w3.org/TR/ldpatch/
[LD-Patch doc]:   https://ruby-rdf.github.io/ld-patch
