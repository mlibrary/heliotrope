# heliotrope

[![Build Status](https://travis-ci.org/mlibrary/heliotrope.svg?branch=master)](https://travis-ci.org/mlibrary/heliotrope)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/heliotrope/badge.svg?branch=master)](https://coveralls.io/github/mlibrary/heliotrope?branch=master)
[![Stories in Ready](https://badge.waffle.io/mlibrary/heliotrope.png?label=ready&title=Ready)](https://waffle.io/mlibrary/heliotrope)

[Samvera](https://wiki.duraspace.org/display/samvera/Samvera) based digital publishing platform built by the [University of Michigan Library](https://www.lib.umich.edu/)

## Development

### Prerequisites

  * [install redis](https://github.com/mlibrary/heliotrope/wiki/Background-Jobs#how-to-install-redis)
  * install mysql ([Install MySQL OS X El Capitan](https://github.com/mlibrary/heliotrope/wiki/Install-MySQL-on-OS-X-El-Capitan))

### Initial setup

```
$ git clone https://github.com/mlibrary/heliotrope.git
$ cd heliotrope
$ bundle install
$ ./bin/bundle exec ./bin/setup
$ ./bin/bundle exec ./bin/rails jekyll:deploy
```  
See Wiki page [Static Pages and Blog](https://github.com/mlibrary/heliotrope/wiki/Static-Pages-and-Blog) for more information on [jekyll](https://jekyllrb.com/) integration.

#### Make yourself a "platform" admin

There is a rails task you can use to create a "platform" admin user.  It will prompt you for an email address and password, and then create a user with the correct role.
```
$ ./bin/bundle exec ./bin/rails admin
```
If you need to run this when the app has been deployed, run:
```
$ RAILS_ENV=production ./bin/bundle exec ./bin/rails admin
```
#### Give yourself an admin role

```
$ vi ./config/role_map.yml
```
```
development:
  admin:   
    - yourself@domain.com 
  archivist:
    - archivist1@example.com
...
```

#### Run the application

Run this command to start Fedora, Solr and Rails servers:
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

Note, there are also config files available for running the wrappers (which save you from having to remember ports, collection names etc). Their settings attempt to persist your Solr index as you move between dev and test. Use like so:
```
$ fcrepo_wrapper --config .wrap_conf/fcrepo_dev
$ solr_wrapper --config .wrap_conf/solr_dev
```

#### Create [default administrative set](https://github.com/samvera/hyrax#create-default-administrative-set) and load [workflows](https://github.com/samvera/hyrax/wiki/Defining-a-Workflow)
```
$ ./bin/bundle exec ./bin/rails hyrax:default_admin_set:create
$ ./bin/bundle exec ./bin/rails hyrax:workflow:load
```
## Debugging

### Explain Partials

Set the EXPLAIN_PARTIALS environment variable to show partials being rendered in source html of your views
(view this info using your browser's inspect element mode)

```
$ EXPLAIN_PARTIALS=true ./bin/bundle exec ./bin/rails s
```

*NOTE:* Because this feature can add a fair bit of overhead, it is restricted
to only run in development mode.

## Testing

To exectue the continuous integration task run by Travis CI

```
$ ./bin/bundle exec ./bin/rails ci
```

Alternatively, you can start up each server individually.  This may be preferable because the ci task starts up and tears down Fedora and Solr before/after the test suite is run.

1. Start up FCrepo
```
$ fcrepo_wrapper -p 8986 --no-jms 
```
or
```
$ fcrepo_wrapper --config .wrap_conf/fcrepo_test
```
1. Start up Solr
```
$ solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test 
```
or
```
$ solr_wrapper --config .wrap_conf/solr_test
```
1. Run tests
```
$ ./bin/bundle exec ./bin/rails rubocop
$ ./bin/bunlde exec ./bin/rails ruumba
$ ./bin/bundle exec ./bin/rails lib_spec
$ ./bin/bundle exec rspec
```
*NOTE:* As of June 20, 2017 we have a test that requires the static pages to be built in order for routing to happen correctly (See the Wiki for more details) which means you need to execute
`./bin/bundle exec ./bin/rails jekyll:deploy` to run rspec.  This need only be done once and if you followed the initial setup then you did this already.

## Wiki

For additional details and helpful hints [read the wiki.](https://github.com/mlibrary/heliotrope/wiki)

## Contact

Contact the [Fulcrum Developers List](mailto:fulcrum-dev@umich.edu) with any question about the project.
