# Ldpath

This is a ruby implementation of [LDPath](http://marmotta.apache.org/ldpath/language.html), a language for selecting values linked data resources.

[![Gem Version](https://badge.fury.io/rb/ldpath.png)](http://badge.fury.io/rb/ldpath)
[![Build Status](https://travis-ci.org/samvera-labs/ldpath.png?branch=master)](https://travis-ci.org/samvera-labs/ldpath)
[![Coverage Status](https://coveralls.io/repos/github/samvera-labs/ldpath/badge.svg?branch=master)](https://coveralls.io/github/samvera-labs/ldpath?branch=master)

## Installation

### Required gem installation

Add this line to your application's Gemfile:

    gem 'ldpath'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ldpath

### Additional gem installations

To support RDF serializations, you will need to either install the [linkeddata gem](https://github.com/ruby-rdf/linkeddata) which installs a large set of RDF serializations or, in order to have a smaller dependency footprint, install gems for only the serializations your plan to use in your app.  The list of serializations are in the [README](https://github.com/ruby-rdf/linkeddata/blob/develop/README.md#features) for the linkeddata gem.

## Usage

```ruby
require 'ldpath'

my_program = <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
EOF

uri = RDF::URI.new "info:a"

context = RDF::Graph.new << [uri, RDF::Vocab::DC.title, "Some Title"]

program = Ldpath::Program.parse my_program
output = program.evaluate uri, context: context
# => { ... }
```

## Compatibility

* Ruby 2.5 or the latest 2.4 version is recommended.  Later versions may also work.

## Product Owner & Maintenance

LDPath is moving toward being a Core Component of the Samvera community. The documentation for
what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[elrayle](https://github.com/elrayle)

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

### Special thanks to...

[Chris Beer](https://github.com/cbeer) for the initial implementation of this gem!
