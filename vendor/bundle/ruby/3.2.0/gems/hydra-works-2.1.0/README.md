# Hydra::Works

Code:
[![Gem Version](https://badge.fury.io/rb/hydra-works.png)](http://badge.fury.io/rb/hydra-works)
[![Build Status](https://circleci.com/gh/samvera/hydra-works.svg?style=svg)](https://circleci.com/gh/samvera/hydra-works)
[![Coverage Status](https://coveralls.io/repos/samvera/hydra-works/badge.svg?branch=main)](https://coveralls.io/r/samvera/hydra-works?branch=main)
[![Code Climate](https://codeclimate.com/github/samvera/hydra-works/badges/gpa.svg)](https://codeclimate.com/github/samvera/hydra-works)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/hydra-works)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is hydra-works?
The Hydra::Works gem implements the [PCDM](https://github.com/duraspace/pcdm/wiki) [Works](https://github.com/duraspace/pcdm/blob/main/pcdm-ext/works.rdf) data model using ActiveFedora-based models. In addition to the models, Hydra::Works includes associated behaviors around the broad concept of describable "works" or intellectual entities, the need for which was expressed by a variety of [Samvera community use cases](https://github.com/samvera/hydra-works/tree/main/use-cases).

## Product Owner & Maintenance

`hydra-works` was a Core Component of the Samvera Community. Given a decline in available labor required for maintenance, this project no longer has a dedicated Product Owner. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

**Vacant**

_Until a Product Owner has been identified, we ask that you please direct all requests for support, bug reports, and general questions to the [`#dev` Channel on the Samvera Slack](https://samvera.slack.com/app_redirect?channel=dev)._

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Getting Started
The PCDM Works domain model includes the following high-level entities:

 * **Collection**: a *pcdm:Collection* that indirectly contains zero or more **Works** and zero or more **Collection**s
 * **Work**: a *pcdm:Object* that holds zero or more **FileSets** and zero or more **Works**
 * **FileSet**: a *pcdm:Object* that groups one or more related *pcdm:Files*, such as an original file (e.g., PDF document), its derivatives (e.g., a thumbnail), and extracted full-text

View [a diagram of the Hydra::Works domain model](https://docs.google.com/drawings/d/1if47TYgEhqDLPh3D0026B_cBLa0BEAOpWPs8AqoQMZE/edit).

Behaviors included in the model include:

 * Characterization of original files within FileSets
 * Generation of derivatives from original files
 * Virus checking of original files
 * Full-text extraction from original files

## Dependencies

Check out the [Hydra::Derivatives README](https://github.com/samvera/hydra-derivatives#dependencies) for dependencies.

## Additional dependencies required for specs

#### ClamAV
* Mac installation
  ```
  $ brew install clamav
  $ cp /usr/local/etc/clamav/freshclam.conf.sample /usr/local/etc/clamav/freshclam.conf
  $ freshclam
  ```

## Installation

Add these lines to your application's Gemfile:

    gem 'hydra-works', '~> 0.15'

And then execute:

    $ bundle install

Or install it yourself:

    $ gem install hydra-works

## Usage

Usage involves extending the behavior provided by this gem. In your application, you can create Hydra::Works-based models like so:

```ruby
class Collection < ActiveFedora::Base
  include Hydra::Works::CollectionBehavior
end

class Book < ActiveFedora::Base
  include Hydra::Works::WorkBehavior
end

class Page < ActiveFedora::Base
  include Hydra::Works::FileSetBehavior
end

collection = Collection.create
book = Book.create
page = Page.create

collection.members << book
collection.save

book.members << page
book.save

file = page.files.build
file.content = "The quick brown fox jumped over the lazy dog."
page.save
```

## Virus Detection

To turn on virus detection, install [ClamAV](https://www.clamav.net/documents/installing-clamav) on your system and add the `clamby` gem to your Gemfile

```ruby
gem 'clamby'
```

Then include the `VirusCheck` module in your `FileSet` class:

```ruby
class Page < ActiveFedora::Base
  include Hydra::Works::FileSetBehavior
  include Hydra::Works::VirusCheck
end
```

## Access controls

We are using [Web ACL](http://www.w3.org/wiki/WebAccessControl) as implemented by [hydra-access-controls](https://github.com/samvera/hydra-head/tree/main/hydra-access-controls).

## How to contribute

If you'd like to contribute to this effort, please check out the [contributing guidelines](CONTRIBUTING.md)

## Development

### Testing with the continuous integration server

You can test Hydra::Works using the same process as our continuous
integration server. To do that, run the default rake task which will download Solr and Fedora, start them,
and run the tests for you.

```bash
rake
```

### Testing manually

If you want to run the tests manually, first run solr and FCRepo. To start solr:

```bash
solr_wrapper -v -d solr/config/ -n hydra-test -p 8985
```

To start FCRepo, open another shell and run:

```bash
fcrepo_wrapper -v -p 8986 --no-jms
```
Note you won't find these ports mentioned in this codebase, as testing behavior is inherited from ActiveFedora.

Now you’re ready to run the tests. In the directory where hydra-works
is installed, run:

```bash
rake works:spec
```

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
