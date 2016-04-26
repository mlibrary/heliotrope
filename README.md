# heliotrope [![Build Status](https://travis-ci.org/curationexperts/heliotrope.svg?branch=master)](https://travis-ci.org/curationexperts/heliotrope)
Hydra-based digital publisher platform

## Development

### Initial setup

  * clone the repository
  * run `bundle install`
  * run `bundle exec bin/setup`
  * [install redis](https://github.com/curationexperts/heliotrope/wiki/Background-Jobs#how-to-install-redis)

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

### Run Resque Workers for Background Jobs

Heliotrope uses resque to process background jobs, such as characterizing files with FITS and creating derivatives (thumbnails, web-friendly video, etc.). In production we recommend resque-pool for managing resque workers. In development, you can use the relevant rake tasks. 

To start worker(s) to run the jobs:
```
QUEUE=* VERBOSE=1 rake resque:work
```

To see the status of recent jobs in the browser console:
```
resque-web -N curation_concerns:development
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
