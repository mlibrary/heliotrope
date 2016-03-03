# heliotrope
Hydra-based digital publisher platform

## Testing

1. Start up FCrepo
   `fcrepo_wrapper -p 8986 --no-jms`
1. Start up Solr
   `solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test`
1. Run tests
   `rspec`
