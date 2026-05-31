RDF/JSON Support for RDF.rb
===========================

This is an [RDF.rb][] extension that adds support for parsing/serializing
[RDF/JSON][], a simple JSON-based RDF serialization format.

[![Gem Version](https://badge.fury.io/rb/rdf-json.png)](https://badge.fury.io/rb/rdf-json)
[![Build Status](https://github.com/ruby-rdf/rdf-json/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-json/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-json/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-json?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

Documentation
-------------

* {RDF::JSON}
  * {RDF::JSON::Format}
  * {RDF::JSON::Reader}
  * {RDF::JSON::Writer}
  * {RDF::JSON::Extensions}

Dependencies
------------

* [RDF.rb](http://rubygems.org/gems/rdf) (~> 3.2)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `RDF::JSON` gem, do:

    % [sudo] gem install rdf-json

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/rdf-json.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget http://github.com/ruby-rdf/rdf-json/tarball/master

Mailing List
------------

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

Author
------

* [Arto Bendiken](http://github.com/ruby-rdf) - <http://ar.to/>

Contributors
------------

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
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[RDF.rb]:   http://www.rubydoc.info/github/ruby-rdf/rdf/
[RDF/JSON]: http://www.w3.org/TR/2013/NOTE-rdf-json-20131107/
[YARD]:             http://yardoc.org/
[YARD-GS]:          http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
