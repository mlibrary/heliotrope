# Heliotrope
Code: [![Build Status](https://travis-ci.org/mlibrary/heliotrope.svg?branch=master)](https://travis-ci.org/mlibrary/heliotrope)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/heliotrope/badge.svg?branch=master)](https://coveralls.io/github/mlibrary/heliotrope?branch=master)

Thanks to [Skylight](https://www.skylight.io/support/skylight-for-open-source): [![View performance data on Skylight](https://badges.skylight.io/status/TtaAmIlZOoFS.svg)](https://oss.skylight.io/app/applications/TtaAmIlZOoFS)

Jump In: [Issue Tracker](https://tools.lib.umich.edu/jira/projects/HELIO/issues)

# Table of Contents
* [What is Fulcrum? What is Heliotrope?](#what-is-fulcrum-what-is-heliotrope)
  * [Feature List](#feature-list)
* [Help/Contact](#helpcontact)
* [Getting started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Initial setup](#initial-setup)
* [Debugging](#debugging)
* [Testing](#testing)
* [License](#license)
* [Contributing](#contributing)
* [Acknowledgements](#acknowledgements)

# What is Fulcrum? What is Heliotrope?
[Fulcrum](https://www.fulcrum.org) is an in-development publishing platform and set of hosting and publishing services aimed to help scholarly publishers present the full richness of their authors' research outputs in a durable, discoverable, and flexible form. Its first phase of development is focused on providing branded companion websites for books. Now, in its second phase, it will expand to host complete e-book collections, journals, and new forms of multimodal publications as well as provide a set of hosting and publishing services for publishers.

**Heliotrope** is the codebase behind the Fulcrum publishing platform. It is a Rails application that extends [Hyrax](https://github.com/samvera/hyrax)–the popular front-end repository solution from the [Samvera open source community](https://samvera.org/)–to provide solutions for scholarly publishers.

It is built by the [University of Michigan Library](https://www.lib.umich.edu) and managed by the Library's publishing division, [Michigan Publishing](https://www.publishing.umich.edu).

## Feature List
In addition to the [features that come with Hyrax](https://github.com/samvera/hyrax/wiki/Feature-matrix), Heliotrope offers the following:
* Web-based e-book reader for [FileSets](http://pcdm.org/works#FileSet) that are valid EPUBs. The e-book reader is delivered as a single-page JS application that is included with Heliotrope as a gem. [See the wiki for more details and features](https://github.com/mlibrary/heliotrope/wiki/EPUB-Reader) specific to the e-book reader. ([Example](http://hdl.handle.net/2027/fulcrum.t722h883s))
* Publisher catalog page listing [Works](http://pcdm.org/works#Work) associated with publisher ([Example](https://www.fulcrum.org/michigan)).
* Customized branding (logo, colors, fonts) for publisher that is applied to associated Works and FileSets ([Example](https://www.fulcrum.org/concern/monographs/w0892995q)).
* Publisher-specific usage analytics (eg, support for multiple Google Analytics IDs on a single page, allowing each publisher to have their own Google Analytics property).
* Bulk importer for Works and their children.
* Embed codes for FileSets, allowing FileSets to be embedded into external websites and EPUB files.
* Support for FileSets that are hosted externally  ([Example](https://www.fulcrum.org/concern/file_sets/zg64tk984)).
* Additional metadata fields for Books and their associated media.
* Accessibility improvements to meet Section 508 and [WCAG 2.0AA guidelines](https://www.w3.org/TR/WCAG20/).
* Delivery of time-based media through an accessible media player, [AblePlayer](https://ableplayer.github.io/ableplayer/). Support for transcripts and captions when provided ([Example](https://www.fulcrum.org/concern/file_sets/jh343s28d)).
* Delivery of [IIIF](http://iiif.io/)-served images using Leaflet ([Example](https://www.fulcrum.org/concern/file_sets/s7526c42w)).
* Integration with [Jekyll](https://jekyllrb.com/) static-site generator for "aboutware" static pages and blog.

# Help/Contact
For additional details and helpful hints [read our ever growing Wiki](https://github.com/mlibrary/heliotrope/wiki). To get in touch with us over e-mail, contact the [Fulcrum Developers List](mailto:fulcrum-dev@umich.edu). To stay updated with developments in Heliotrope and Fulcrum, [sign-up for our newsletter](https://www.fulcrum.org/#get-updates).

# Getting started

## Prerequisites
  * Install and configure [Hyrax prerequisites](https://github.com/samvera/hyrax#prerequisites).
  * [Install redis](https://github.com/mlibrary/heliotrope/wiki/Background-Jobs#how-to-install-redis)
  * Install mysql ([Install MySQL OS X El Capitan](https://github.com/mlibrary/heliotrope/wiki/Install-MySQL-on-OS-X-El-Capitan))

## Initial setup
### 1. Getting a local copy, bundle install gems, and execute setup script

```
$ git clone https://github.com/mlibrary/heliotrope.git
$ cd heliotrope
$ bundle install
$ ./bin/bundle exec ./bin/setup
```  
See the [Wiki](https://github.com/mlibrary/heliotrope/wiki/Static-Pages-and-Blog) for information on [Jekyll](https://jekyllrb.com/) integration.

### 2. Create users
#### Make yourself a "platform" admin
There is a rails task you can execute to create a "platform" admin user. It will prompt you for an email address and then create a user with the correct role.
```
$ ./bin/bundle exec ./bin/rails admin
```

If you need to run this when the app has been deployed, execute:
```
$ RAILS_ENV=production ./bin/bundle exec ./bin/rails admin
```

### 3. Run the application

Execute this command to start Fedora, Solr and Rails servers:
```
$ ./bin/bundle exec ./bin/rails hydra:server
```
Or, if you prefer to start each server individually execute each of the following commands in a seperate shells: *(you must use this alternate option if running on a VM)*

```
$ redis-server /usr/local/etc/redis.conf
$ fcrepo_wrapper -p 8984 --no-jms
$ solr_wrapper -p 8983 -d solr/config/ --collection_name hydra-development
$ ./bin/bundle exec ./bin/rails s
```
*NOTE:* You'll also want to make sure that you have MySQL started.

*NOTE:* There are also config files available for running the wrappers (which save you from having to remember ports, collection names etc). Their settings attempt to persist your Solr index as you move between dev and test. Use like so:
```
$ fcrepo_wrapper --config .wrap_conf/fcrepo_dev
$ solr_wrapper --config .wrap_conf/solr_dev
```

### 4. Create [default administrative set](https://github.com/samvera/hyrax#create-default-administrative-set)
```
$ ./bin/bundle exec ./bin/rails hyrax:default_admin_set:create
```

# Debugging
## Explain Partials
When running Rails server, set the `EXPLAIN_PARTIALS` environment variable to show partials being rendered in source html of your views. You can view this info using your browser's inspect element mode.

```
$ EXPLAIN_PARTIALS=true ./bin/bundle exec ./bin/rails s
```

*NOTE:* Because this feature can add a fair bit of overhead, it is restricted
to only run in development mode.

# Testing
To execute the continuous integration task run by Travis CI

```
$ ./bin/bundle exec ./bin/rails ci
```

## Starting servers individually when testing
Alternatively, you can start up each server individually.  This may be preferable because the ci task starts up and tears down Fedora and Solr before/after the test suite is run.

### 1. Start up FCrepo
```
$ fcrepo_wrapper -p 8986 --no-jms
```
or
```
$ fcrepo_wrapper --config .wrap_conf/fcrepo_test
```
### 2. Start up Solr
```
$ solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test
```
or
```
$ solr_wrapper --config .wrap_conf/solr_test
```
### 3. Run tests
```
$ ./bin/bundle exec ./bin/rails rubocop
$ ./bin/bunlde exec ./bin/rails ruumba
$ ./bin/bundle exec ./bin/rails lib_spec
$ ./bin/bundle exec rspec
```

## Running specs individually
To run individual specs located in the `./lib/spec directory` (a.k.a lib_spec) first step into the lib directory and then execute rspec.
```
$ cd lib
$ ../bin/bundle exec rspec
```

## Special note on running tests
As of June 20, 2017 there are tests that require the static pages to be built in order for routing to happen correctly (See [Static Pages and Blog](https://github.com/mlibrary/heliotrope/wiki/Static-Pages-and-Blog) documentation). This means you need to execute
```
$ ./bin/bundle exec ./bin/rails jekyll:deploy
```
before running rspec.  This only need be executed once. If you followed step 1 of the [initial setup](#initial-setup) then you did this already.

# License
Heliotrope is available under the [Apache 2.0 license](LICENSE.md).

# Contributing
We'd love to accept your contributions and there are lots of ways to engage with the Fulcrum project and Heliotrope codebase even if you aren't a developer. Please see our [contributing guidelines](https://github.com/mlibrary/heliotrope/wiki/How-to-Contribute) for how you can get involved.

Please note: As of May 14 2018, we have migrated our issues to a [JIRA project](https://tools.lib.umich.edu/jira/projects/HELIO/issues) and are no longer creating new issues in GitHub. All GitHub issues that were open at the time of migration will be updated with relevant links to the corresponding JIRA issue. If you find bugs or would like to open an issue, you can still use GitHub for that to open the conversation with Fulcrum developers.

# Acknowledgements
Initial development has been supported by a generous grant from the [Andrew W. Mellon Foundation](https://mellon.org/) and implemented by the University of Michigan Library and Press working with partners from Indiana, Minnesota, Northwestern, and Penn State universities and [Data Curation Experts](https://curationexperts.com/).
