# Extended XSD Datatypes and XQuery functions for RDF.rb

This gem adds additional RDF::Literal subclasses for extended [XSD datatypes][] along with methods implementing many [XPath and XQuery Functions][]

[![Gem Version](https://badge.fury.io/rb/rdf-xsd.png)](https://badge.fury.io/rb/rdf-xsd)
[![Build Status](https://github.com/ruby-rdf/rdf-xsd/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-xsd/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-xsd/badge.svg)](https://coveralls.io/github/ruby-rdf/rdf-xsd?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Features

* Additional xsd:integer subtypes
* xsd:float based on xsd:double
* xsd:duration, xsd:yearMonthDuration, and xsd:dayTimeDuration.
* rdf:XMLLiteral
* XML Exclusive Canonicalization (Nokogiri & REXML)
* XML Literal comparisons (EquivalentXml, ActiveSupport or String)

## Examples

    require 'rdf'
    require 'rdf/xsd'

## Dependencies
* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* Soft dependency on [Nokogiri](https://rubygems.org/gems/nokogiri) (>= 1.12)
* Soft dependency on [EquivalentXML](https://rubygems.org/gems/equivalent-xml) (~> 0.6)
* Soft dependency on [ActiveSupport](https://rubygems.org/gems/activesupport) (~> 6.2)

## Documentation
Full documentation available on [GitHub][XSD doc]

### Principle Classes
* {RDF::Literal::Base64Binary}
* {RDF::Literal::Duration}
    * {RDF::Literal::YearMonthDuration}
    * {RDF::Literal::DayTimeDuration}
* {RDF::Literal::Float}
* {RDF::Literal::HexBinary}
* {RDF::Literal::NonPositiveInteger}
    * {RDF::Literal::NegativeInteger}
* {RDF::Literal::Long}
    * {RDF::Literal::Int}
        * {RDF::Literal::Short}
            * {RDF::Literal::Byte}
* {RDF::Literal::NonNegativeInteger}
    * {RDF::Literal::PositiveInteger}
    * {RDF::Literal::UnsignedLong}
        * {RDF::Literal::UnsignedInt}
            * {RDF::Literal::UnsignedShort}
                * {RDF::Literal::UnsignedByte}
* {RDF::Literal::YearMonth}
* {RDF::Literal::Year}
* {RDF::Literal::MonthDay}
* {RDF::Literal::Month}
* {RDF::Literal::Day}
* {RDF::Literal::XML}

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `RDF::XSD` gem, do:

    % [sudo] gem install rdf-xsd

## Mailing List

* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author

* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

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

Portions of tests are derived from [W3C DAWG tests](https://www.w3.org/2001/sw/DataAccess/tests/) and have [other licensing terms](https://www.w3.org/2001/sw/DataAccess/tests/data-r2/LICENSE).

[Ruby]:       https://ruby-lang.org/
[RDF]:        https://www.w3.org/RDF/
[YARD]:       https://yardoc.org/
[YARD-GS]:    https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[Backports]:  https://rubygems.org/gems/backports
[XSD Datatypes]: https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#built-in-datatypes
[XPath and XQuery Functions]: https://www.w3.org/TR/xpath-functions/
[XSD Doc]: https://ruby-rdf.github.io/rdf-xsd