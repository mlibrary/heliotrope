# Valkyrie

Valkyrie is a gem for enabling multiple backends for storage of files and metadata in Samvera.

![Valkyrie Logo](valkyrie_logo.png)

Code: [![Gem Version](https://badge.fury.io/rb/valkyrie.svg)](https://badge.fury.io/rb/valkyrie)
[![Build Status](https://circleci.com/gh/samvera/valkyrie.svg?style=svg)](https://circleci.com/gh/samvera/valkyrie)
![Coverage Status](https://img.shields.io/badge/Coverage-100-brightgreen.svg)

Docs: [![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/gems/valkyrie)

Jump in: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

## Primary Contacts

### Product Owner
[Alexandra Dunn](https://github.com/dunn)

### Technical Lead
[Trey Pendragon](https://github.com/tpendragon)

## Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Getting Started

Add this line to your application's Gemfile:

```
gem 'valkyrie'
```

And then execute:

    $ bundle

## Configuration

Valkyrie is configured in two places: an initializer that registers the persistence options and a YAML
configuration file that sets which options are used by default in which environments.

### Sample initializer: `config/initializers/valkyrie.rb`:
Here is a sample initializer that registers a couple adapters and storage adapters, in each case linking an
instance with a short name that can be used to refer to it in your application:


```
# frozen_string_literal: true
require 'valkyrie'


Rails.application.config.to_prepare do

  # To use the postgres adapter you must add `gem 'pg'` to your Gemfile
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Postgres::MetadataAdapter.new,
    :postgres
  )

  # To use the solr adapter you must add gem 'rsolr' to your Gemfile
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Solr::MetadataAdapter.new(
      connection: Blacklight.default_index.connection
    ),
    :solr
  )

  # To use the fedora adapter you must add `gem 'ldp'` to your Gemfile
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Fedora::MetadataAdapter.new(
      connection: ::Ldp::Client.new("http://localhost:8988/rest"),
      base_path: "test_fed",
      schema: Valkyrie::Persistence::Fedora::PermissiveSchema.new(title: RDF::URI("http://bad.com/title"))
    ),
    :fedora
  )

  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Memory::MetadataAdapter.new,
    :memory
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Disk.new(base_path: Rails.root.join("tmp", "files")),
    :disk
  )

  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Fedora.new(connection: Ldp::Client.new("http://localhost:8988/rest")),
    :fedora
  )


  Valkyrie::StorageAdapter.register(
    Valkyrie::Storage::Memory.new,
    :memory
  )
end
```

The initializer registers four `Valkyrie::MetadataAdapter` instances for storing metadata:
* `:fedora` which stores metadata in a Fedora server.
* `:memory` which stores metadata in an in-memory cache (this cache is not persistent, so it is only
  appropriate for testing).
* `:postgres` which stores metadata in a PostgreSQL database.
* `:solr` which stores metadata in a Solr Index (Solr Persister issues a warning if it has to generate an ID for a new resource because it is intended to be used as a secondary persister).

Other adapter options include `Valkyrie::Persistence::BufferedPersister` for buffering in memory before bulk
updating another persister, `Valkyrie::Persistence::CompositePersister` for storing in more than one adapter
at once, `Valkyrie::Persistence::Solr` for storing in Solr, and `Valkyrie::Persistence::Fedora` for storing
in Fedora.

The initializer also registers three `Valkyrie::StorageAdapter` instances for storing files:
* `:disk` which stores files on disk
* `:fedora` which stores files in Fedora
* `:memory` which stores files in an in-memory cache (again, not persistent, so this is only appropriate for
  testing)

### Sample configuration with custom `Valkyrie.config.resource_class_resolver`:
```
require 'valkyrie'
Rails.application.config.to_prepare do
  Valkyrie.config.resource_class_resolver = lambda do |resource_klass_name|
    # Do complicated lookup based on the string
  end
end
```

### Sample configuration: `config/valkyrie.yml`:
A sample configuration file that configures your application to use different adapters:

```
development:
  metadata_adapter: postgres
  storage_adapter: disk

test:
  metadata_adapter: memory
  storage_adapter: memory

production:
  metadata_adapter: postgres
  storage_adapter: fedora
```

For each environment, you must set two values:
* `metadata_adapter` is the store where Valkyrie will put the metadata
* `storage_adapter` is the store where Valkyrie will put the files

The values are the short names used in your initializer.

Further details can be found on the [Persistence Wiki
page](https://github.com/samvera/valkyrie/wiki/Persistence).

## Usage

### Define a Custom Work
Define a custom work class:

```
# frozen_string_literal: true
class MyModel < Valkyrie::Resource
  include Valkyrie::Resource::AccessControls
  attribute :title, Valkyrie::Types::Set    # Sets deduplicate values
  attribute :date, Valkyrie::Types::Array   # Arrays can contain duplicate values
end
```

Attributes are unordered by default.  Adding `ordered: true` to an attribute definition will preserve the
order of multiple values.

```
attribute :authors, Valkyrie::Types::Array.meta(ordered: true)
```

Defining resource attributes is explained in greater detail on the [Using Types Wiki
page](https://github.com/samvera/valkyrie/wiki/Using-Types).

### Read and Write Data
```
# initialize a metadata adapter
adapter = Valkyrie::MetadataAdapter.find(:postgres)

# create an object
object1 = MyModel.new title: 'My Cool Object', authors: ['Jones, Alice', 'Smith, Bob']
object1 = adapter.persister.save(resource: object1)

# load an object from the database
object2 = adapter.query_service.find_by(id: object1.id)

# load all objects
objects = adapter.query_service.find_all

# load all MyModel objects
Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: MyModel)
```

The Wiki documents the usage of [Queries](https://github.com/samvera/valkyrie/wiki/Queries),
[Persistence](https://github.com/samvera/valkyrie/wiki/Persistence), and
[ChangeSets and Dirty Tracking](https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking).

### Concurrency Support
A Valkyrie repository may have concurrent updates, for example, from a load-balanced Rails application, or
from multiple [Sidekiq](https://github.com/mperham/sidekiq) background workers).  In order to prevent multiple
simultaneous updates applied to the same resource from losing or corrupting data, Valkyrie supports optimistic
locking.  How to use optimistic locking with Valkyrie is documented on the [Optimistic Locking Wiki
page](https://github.com/samvera/valkyrie/wiki/Optimistic-Locking).

### The Public API
Valkyrie's public API is defined by the shared specs that are used to test each of its core classes.
This include change sets, resources, persisters, adapters, and queries. When creating your own kinds of
these kinds of classes, you should use these shared specs to test your classes for conformance to
Valkyrie's API.

When breaking changes are introduced, necessitating a major version change, the shared specs will reflect
this. When new features are added and a minor version is released there will be no change to the existing
shared specs, but there may be new ones. These new shared specs will fail in your application if you have
custom adapters, but your application will still work.

Using the shared specs in your own models is described in more detail on the [Shared Specs Wiki
page](https://github.com/samvera/valkyrie/wiki/Shared-Specs).

### Fedora 5/6 Compatibility
When configuring your adapter, include the `fedora_version` parameter in your metadata or storage adapter
config.  If Fedora requires auth, you can also include that in the URL, e.g.:

   ```
   Valkyrie::Storage::Fedora.new(
     connection: Ldp::Client.new("http://fedoraAdmin:fedoraAdmin@localhost:8988/rest"),
     fedora_version: 5
   )
   ```

## Installing a Development environment

For ease of development we use Lando to abstract away some complications of
using Docker containers for development.

### Running Tests

1. Install the latest released > 3.0 version of Lando from [here](https://github.com/lando/lando/releases).
2. `bundle install`(Ruby 2.6+ required)
3. `bundle exec rake server:start`
4. `bundle exec rspec spec`

### Cleaning Data

1. `bundle exec rake server:clean`

### Stopping Servers

1. `bundle exec rake server:stop`

You can also run `lando poweroff` from anywhere.

## Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samvera/valkyrie/.

If you're working on PR for this project, create a feature branch off of `main`.

If you’re developing an application that uses Valkyrie, consider adding it to
the [list of Valkyrie apps](https://github.com/samvera/valkyrie/wiki/Valkyrie-Apps)!

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.
