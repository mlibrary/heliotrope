# Hydra::PCDM

Code:
[![Gem Version](https://badge.fury.io/rb/hydra-pcdm.png)](http://badge.fury.io/rb/hydra-pcdm)
[![Build Status](https://circleci.com/gh/samvera/hydra-pcdm.svg?style=svg)](https://circleci.com/gh/samvera/hydra-pcdm)
[![Coverage Status](https://coveralls.io/repos/samvera/hydra-pcdm/badge.svg?branch=main)](https://coveralls.io/r/samvera/hydra-pcdm?branch=main)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/hydra-pcdm)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is hydra-pcdm?

Samvera implementation of the Portland Common Data Model (PCDM)

## Product Owner & Maintenance

`hydra-pcdm` was a Core Component of the Samvera Community. Given a decline in available labor required for maintenance, this project no longer has a dedicated Product Owner. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

**Vacant**

_Until a Product Owner has been identified, we ask that you please direct all requests for support, bug reports, and general questions to the [`#dev` Channel on the Samvera Slack](https://samvera.slack.com/app_redirect?channel=dev)._

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Installation

Add these lines to your application's Gemfile:

```ruby
  gem 'active-fedora', '~> 9.3'
  gem 'hydra-pcdm', '~> 0.9'
```

And then execute:

    $ bundle install

Or install it yourself:

    $ gem install hydra-pcdm

## Access Controls

We are using [Web ACL](http://www.w3.org/wiki/WebAccessControl) as implemented in [hydra-access-controls](https://github.com/samvera/hydra-head/tree/main/hydra-access-controls).

## Portland Common Data Model

Reference: [Portland Common Data Model](https://github.com/duraspace/pcdm/wiki)

### Model Definition

![PCDM Model Definition](https://raw.githubusercontent.com/wiki/duraspace/pcdm/images/coll-object-file.png)

## Usage

Hydra::PCDM provides three core classes:

```
Hydra::PCDM::Object
Hydra::PCDM::Collection
Hydra::PCDM::File
```

A `Hydra::PCDM::File` is a NonRDFSource (in [LDP](http://www.w3.org/TR/ldp/) parlance) &emdash; a bitstream. You can use this to store content. A PCDM::File is contained by a PCDM::Object. A `File` may have some attached technical metadata, but no descriptive metadata. A `Hydra::PCDM::Object` may contain `File`s, may have descriptive metadata, and may declare other `Object`s as members (for complex object hierarchies). A `Hydra::PCDM::Collection` may contain other `Collection`s or `Object`s but may not directly contain `File`s. A `Collection` may also have descriptive metadata.

Typically, usage involves extending the behavior provided by this gem. In your application you can write something like this:

```ruby
class Book < ActiveFedora::Base
  include Hydra::PCDM::ObjectBehavior
end

class Collection < ActiveFedora::Base
  include Hydra::PCDM::CollectionBehavior
end

collection = Collection.create
book = Book.create

collection.members = [book]
# or: collection.members << book
collection.save

file = book.files.build
file.content = "The quick brown fox jumped over the lazy dog."
book.save
```
# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
