# Testing
## Configuration
./testing/testing.yml
```yaml
testing:
  source_url: 'https://www.fulcrum.org/'
  source_token: ''
  target_url: 'https://heliotrope-testing.hydra.lib.umich.edu/'
  target_token: ''
```
## Rake Task
To run testing specs

`./bin/bundle exec ./bin/rails testing_spec`

To run individual specs located in the ./testing/spec directory (a.k.a. testing_spec) first step into the testing drectory and then execute rspec.
```bash
$ cd testing
$ ../bin/bundle exec rspec
```
