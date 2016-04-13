# heliotrope [![Build Status](https://travis-ci.org/curationexperts/heliotrope.svg?branch=master)](https://travis-ci.org/curationexperts/heliotrope)
Hydra-based digital publisher platform

## Development

### Initial setup

  * clone the repository
  * run `bundle install`
  * run `bundle exec bin/setup`

#### Install redis

Heliotrope uses redis to store information about the background jobs.

If you are using a mac, you can use homebrew to install redis:

`brew install redis`

and start the redis server like this (change this command depending on where your config file is located):

`redis-server /usr/local/etc/redis.conf`

**VAGRANT**: if you're using a Vagrant box, redis server is probably already installed and running.  
You can check with the following command: `redis-cli ping`, the server should respond with "pong"

#### Create an admin user

There is a rake task you can use to create a superadmin user.  It will prompt you for an email address and password, and then create a user with the correct role.

`bundle exec rake admin`

### Run the application

Run this command to start Fedora, Solr and Rails servers:

`rake hydra:server`

Or, if you prefer to start each server individually:
*(you must use this alternate option if runnig on a VM)*

```
  $ redis-server /usr/local/etc/redis.conf
  $ bundle exec fcrepo_wrapper -p 8984 --no-jms
  $ bundle exec solr_wrapper -p 8983 -d solr/config/ --collection_name hydra-development
  $ bundle exec bin/rails s
```

## Testing

run `rake ci`

Alternatively, you can start up each server individually.  This may be preferable because `rake ci` starts up and tears down Fedora and Solr before/after the test suite is run.

1. Start up FCrepo

   `fcrepo_wrapper -p 8986 --no-jms`
1. Start up Solr

   `solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test`
1. Run tests

   `rspec`
