# RDF::Microdata reader/writer

[Microdata][] parser for RDF.rb.

[![Gem Version](https://badge.fury.io/rb/rdf-microdata.png)](https://badge.fury.io/rb/rdf-microdata)
[![Build Status](https://github.com/ruby-rdf/rdf-microdata/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-microdata/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-microdata/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-microdata?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## DESCRIPTION
RDF::Microdata is a Microdata reader for Ruby using the [RDF.rb][RDF.rb] library suite.

## FEATURES
RDF::Microdata parses [Microdata][] into statements or triples using the rules defined in [Microdata RDF][].

* Microdata parser.
* Uses Nokogiri for parsing HTML

Install with 'gem install rdf-microdata'

### Living implementation
Microdata to RDF transformation is undergoing active development. This implementation attempts to be up-to-date
as of the time of release, and is being used in developing the [Microdata RDF][] specification.

This implementation includes support for the proposed [``@itemprop-reverse``](https://www.w3.org/wiki/WebSchemas/InverseProperties#Proposed_Action:_New_attribute_.40itemprop-reverse) attribute.

### Microdata Registry
The parser uses a build-in version of the [Microdata RDF][] registry.

## Usage

### Reading RDF data in the Microdata format

    require 'rdf/microdata'
    graph = RDF::Graph.load("etc/doap.html", format: :microdata)

### Reading using content-negotation

    require 'rdf/microdata'
    graph = RDF::Graph.load("etc/doap.html", content_type: "text/html")
    
## Note
This spec is based on the W3C HTML Data Task Force specification and does not support
GRDDL-type triple generation, such as for html>head>title anchor tags.

If the `RDFa` parser is available, {RDF::Microdata::Format} will not assert content type `text/html` or file extension `.html`, as this is also asserted by RDFa. Instead, the RDFa reader will invoke the microdata reader if an `@itemscope` attribute is detected.
  
## Dependencies
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [RDF::RDFa](https://rubygems.org/gems/rdf-xsd) (~> 3.2)
* [RDF::XSD](https://rubygems.org/gems/rdf-xsd) (~> 3.2)
* [HTMLEntities](https://rubygems.org/gems/htmlentities) ('~> 4.3')
* [Nokogiri](https://rubygems.org/gems/nokogiri) (~> 1.12)

## Documentation
Full documentation available on [Rubydoc.info][Microdata doc]

### Principle Classes
* {RDF::Microdata::Format}
  Asserts :html format, text/html mime-type and .html file extension.
* {RDF::Microdata::Reader}
  * {RDF::Microdata::Reader::Nokogiri}


### RDFa-based Reader
There is an experimental reader based on transforming Microdata to RDFa within the DOM. To invoke
this, add the `rdfa: true` option to the {RDF::Microdata::Reader.new}, or
use {RDF::Microdata::RdfaReader} directly.

The reader exposes a `#rdfa` method, which can be used to retrieve the transformed HTML+RDFa

## Resources
* [RDF.rb][RDF.rb]
* [Documentation](https://ruby-rdf.github.io/rdf-microdata/)
* [History](file:History.md)
* [Microdata][]
* [Microdata RDF][]

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

## FEEDBACK

* gregg@greggkellogg.net
* <https://rubygems.org/rdf-microdata>
* <https://github.com/ruby-rdf/rdf-microdata>
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

[RDF.rb]:           https://github.com/ruby-rdf/rdf
[YARD]:             https://yardoc.org/
[YARD-GS]:          https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[Microdata]:        https://dev.w3.org/html5/md/Overview.html                                      "HTML Microdata"
[Microdata RDF]:    https://dvcs.w3.org/hg/htmldata/raw-file/default/microdata-rdf/index.html     "Microdata to RDF"
[Microdata doc]:    https://ruby-rdf.github.io/rdf-microdata/frames
