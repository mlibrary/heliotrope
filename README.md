# heliotrope [![Build Status](https://travis-ci.org/curationexperts/heliotrope.svg?branch=master)](https://travis-ci.org/curationexperts/heliotrope)
Hydra-based digital publisher platform

## Testing

1. Start up FCrepo

   `fcrepo_wrapper -p 8986 --no-jms`
1. Start up Solr

   `solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test`
1. Run tests

   `rspec`


Alternatively you can run `rake ci`, but this is slower because it starts up and tears down Fedora and Solr before/after the test suite is run.


## Development

Run this command to start Fedora, Solr and Rails:

`rake hydra:server`
