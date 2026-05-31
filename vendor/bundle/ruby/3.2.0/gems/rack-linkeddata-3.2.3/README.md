# Linked Data Content Negotiation for Rack Applications

This is [Rack][] middleware that provides [Linked Data][] content
negotiation for Rack applications. You can use `Rack::LinkedData` with any
Ruby web framework based on Rack, including with Ruby on Rails 3.0 and with
Sinatra.

* <https://github.com/ruby-rdf/rack-linkeddata>

[![Gem Version](https://badge.fury.io/rb/rack-linkeddata.svg)](https://badge.fury.io/rb/rack-linkeddata)
[![Build Status](https://github.com/ruby-rdf/rack-linkeddata/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rack-linkeddata/actions?query=workflow%3ACI)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Features

* Implements [HTTP content negotiation][conneg] for RDF content types.
* Supports all [RDF.rb][] compatible serialization formats.
* Compatible with any Rack application and any Rack-based framework.

## Examples

### Adding Linked Data content negotiation to a Rails 3.x application

    # config/application.rb
    require 'rack/linkeddata'
    
    class Application < Rails::Application
      config.middleware.use Rack::LinkedData::ContentNegotiation
    end

### Adding Linked Data content negotiation to a Sinatra application

    #!/usr/bin/env ruby -rubygems
    require 'sinatra'
    require 'rack/linkeddata'
    
    use Rack::LinkedData::ContentNegotiation
    
    get '/hello' do
      RDF::Graph.new do |graph|
        graph << [RDF::Node.new, RDF::DC.title, "Hello, world!"]
      end
    end

### Adding Linked Data content negotiation to a Rackup application

    #!/usr/bin/env rackup
    require 'rack/linkeddata'
    
    rdf = RDF::Graph.new do |graph|
      graph << [RDF::Node.new, RDF::DC.title, "Hello, world!"]
    end
    
    use Rack::LinkedData::ContentNegotiation
    run lambda { |env| [200, {}, rdf] }

### Defining a default Linked Data content type

    use Rack::LinkedData::ContentNegotiation, :default => "text/turtle"

Options are also passed to the writer, which can allow options to be shared among the application
and different components.

    shared_options = {:default => "text/turtle", :standard_prefixes => true, }
    use Rack::LinkedData::ContentNegotiation, shared_options
    run MyApplication, shared_options

### Testing Linked Data content negotiation using `rackup` and `curl`

    $ rackup doc/examples/hello.ru
    
    $ curl -iH "Accept: text/plain" http://localhost:9292/hello
    $ curl -iH "Accept: text/turtle" http://localhost:9292/hello
    $ curl -iH "Accept: application/rdf+xml" http://localhost:9292/hello
    $ curl -iH "Accept: application/json" http://localhost:9292/hello
    $ curl -iH "Accept: application/trix" http://localhost:9292/hello
    $ curl -iH "Accept: */*" http://localhost:9292/hello

## Description

`Rack::LinkedData` implements content negotiation for any [Rack][] response
object that implements the `RDF::Enumerable` mixin. You would typically
return an instance of `RDF::Graph` or `RDF::Repository` from your Rack
application, and let the `Rack::LinkedData::ContentNegotiation` middleware
take care of serializing your response into whatever RDF format the HTTP
client requested and understands.

The middleware queries [RDF.rb][] for the MIME content types of known RDF
serialization formats, so it will work with whatever serialization extensions
that are currently available for RDF.rb. (At present, this includes support
for N-Triples, N-Quads, Turtle, RDF/XML, RDF/JSON, JSON-LD, RDFa, TriG and TriX.)

##Documentation

<https://ruby-rdf.github.io/rack-linkeddata/>

* {Rack::LinkedData}
  * {Rack::LinkedData::ContentNegotiation}

## Dependencies

* [Rack](https://rubygems.org/gems/rack) (~> 2.0)
* [Linked Data](https://rubygems.org/gems/linkeddata) (~> 3.1)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the gem, do:

    % [sudo] gem install rack-linkeddata

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/rack-linkeddata.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget https://github.com/ruby-rdf/rack-linkeddata/tarball/master

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

## References

* <https://www.w3.org/DesignIssues/LinkedData.html>
* <https://linkeddata.org/docs/how-to-publish>
* <https://linkeddata.org/conneg-303-redirect-code-samples>
* <https://www.w3.org/TR/cooluris/>
* <https://www.w3.org/TR/swbp-vocab-pub/>
* <https://patterns.dataincubator.org/book/publishing-patterns.html>

## Authors

* [Arto Bendiken](https://github.com/artob) - <https://ar.to/>
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Rack]:           https://rack.github.com/
[RDF.rb]:         https://ruby-rdf.github.io/rdf/
[Linked Data]:    https://linkeddata.org/
[conneg]:         https://en.wikipedia.org/wiki/Content_negotiation
[YARD]:            https://yardoc.org/
[YARD-GS]:         https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:             https://unlicense.org/#unlicensing-contributions
