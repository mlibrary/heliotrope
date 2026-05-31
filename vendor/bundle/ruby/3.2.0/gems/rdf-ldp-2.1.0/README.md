RDF::LDP
========
[![Gem Version](https://badge.fury.io/rb/rdf-ldp.png)](https://badge.fury.io/rb/rdf-ldp)
[![Build Status](https://github.com/ruby-rdf/rdf-ldp/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-ldp/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-ldp/badge.svg)](https://coveralls.io/github/ruby-rdf/rdf-ldp)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

Server-side support for Linked Data Platform (LDP) with RDF.rb. To get started
with LDP, see the [LDP Primer](https://dvcs.w3.org/hg/ldpwg/raw-file/default/ldp-primer/ldp-primer.html).

This software ships with the following libraries:

  - `RDF::LDP` --- contains the domain model and behavior for LDP Resources and
  interaction models.
  - `Rack::LDP` --- a suite of Rack middleware for creating LDP servers based on
  `RDF::LDP`.
  - Lamprey --- a basic LDP server implemented with `Rack::LDP`.

Lamprey
=======

Lamprey is a basic LDP server. To start it, use:

```sh
$ gem install rdf-ldp
$ lamprey
```

Lamprey currently uses an in-memory repository, and is therefore not a
persistent datastore out of the box. Backends are swappable, using any
`RDF::Repository` implementation with named graph (`#context`) support. We are
working to complete a recommended, default backend and introduce startup
configuration. See [/CONSTRAINED_BY.md](/CONSTRAINED_BY.md) and
[/IMPLEMENTATION.md](/IMPLEMENTATION.md) for details.

An `ldp:BasicContainer` will be created at the address of your first `GET`
request if the backend store is empty. _Note that if that request is made to the
server root, Sinatra will assume a trailing slash_. You can also create an
initial container (or other resource) with HTTP `PUT`.

```bash
$ curl -i http://localhost:4567

HTTP/1.1 200 OK
Content-Type: text/turtle
Link: <http://www.w3.org/ns/ldp#Resource>;rel="type",<http://www.w3.org/ns/ldp#RDFSource>;rel="type",<http://www.w3.org/ns/ldp#BasicContainer>;rel="type"
Allow: GET, POST, PUT, DELETE, OPTIONS, HEAD
Accept-Post: application/n-triples, text/plain, application/n-quads, text/x-nquads, application/ld+json, application/x-ld+json, application/rdf+json, text/html, text/n3, text/rdf+n3, application/rdf+n3, application/rdf+xml, text/csv, text/tab-separated-values, application/csvm+json, text/turtle, text/rdf+turtle, application/turtle, application/x-turtle, application/trig, application/x-trig, application/trix
Etag: "1B2M2Y8AsgTpgAmY7PhCfg==0"
Vary: Accept
X-Content-Type-Options: nosniff
Server: WEBrick/1.3.1 (Ruby/2.1.0/2013-12-25)
Date: Mon, 27 Jul 2015 23:19:06 GMT
Content-Length: 0
Connection: Keep-Alive
```

Rack::LDP
==========

Setting up a Custom Server
--------------------------

You can quickly create your own server with any framework supporting
[Rack](https://github.com/rack/). The simplest way to do this is with
[Rackup](https://github.com/rack/rack/wiki/(tutorial)-rackup-howto).

```ruby
# ./config.ru

require 'rack/ldp'

use Rack::LDP::ContentNegotiation
use Rack::LDP::Errors
use Rack::LDP::Responses
use Rack::LDP::Requests

# Setup a repository and an initial container:
#
#   - You probably want some persistent repository implementation. The example
#     uses an in-memory repository.
#   - You may not need an initial "base" container, if you handle create on PUT
#     requests.
#
repository = RDF::Repository.new 
RDF::LDP::Container.new(RDF::URI('http://localhost:9292/'), repository)
  .create(StringIO.new(''), 'text/plain') if repository.empty?

app = proc do |env|
  # Return a Rack response, giving an `RDF::LDP::Resource`-like object as the body.
  # The `Rack::LDP` middleware marhsalls the request to the resource, builds the response,
  # and handles conneg for RDF serializations (when the body is an `RDF::LDP::RDFSource`).
  #
  # @see https://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Response
  
  [200, {}, RDF::LDP::Resource.find(RDF::URI(env['REQUEST_URI']), repository)]
end

run app
```

And run your server with: 

```sh
$ rackup
```

Testing
-------

RSpec shared examples for the required behaviors of LDP resource and container
types are included in `rdf/ldp/spec` for use in customized implementations.
Running these example sets will help ensure LDP compliance for specialized
resource behaviors.

This test suite is provided provisionally and may be incomplete or overly
strict. Please [report issues](https://github.com/ruby-rdf/rdf-ldp/issues)
encountered during its use.

```ruby
require 'rdf/ldp/spec'

describe MyResource do
  it_behaves_like 'a Resource'
end

describe MyRDFSource do
  it_behaves_like 'an RDFSource'
end

# ...

describe MyIndirectContainer do
  it_behaves_like 'an IndirectContainer'
end
```

We recommend running the official
[LDP testsuite](https://github.com/cbeer/ldp_testsuite_wrapper), as integration
tests in addition to the above examples.

Compliance
----------

Current compliance reports for Lamprey are located in [/report](report/).
Reports are generated by the LDP test suite. We use the
[`ldp_testsuite_wrapper`](https://github.com/cbeer/ldp_testsuite_wrapper)
gem to run the suite and generate the tests.

RDF.rb Compatibility
--------------------------

As of version 2.1, this software depends on RDF.rb 3.2 or greater.

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

This software is released under a public domain waiver (Unlicense).

[YARD]:             https://yardoc.org/
[YARD-GS]:          https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
