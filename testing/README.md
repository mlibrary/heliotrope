# System Testing
## Shell Envirionment Variables
<table>
	<tr><th>Variable</th><th>Description</th></tr>
	<tr><td>HELIOTROPE_TESTING_API</td><td>Testing target API endpoint. e.g. http://localhost:3000/api </td></tr>
	<tr><td>HELIOTROPE_TESTING_TOKEN</td><td>JSON Web Token of platform administrator user</td></tr>
</table>

## Rake Task
To run testing specs

`./bin/bundle exec ./bin/rails testing_spec`

To run individual specs located in the ./testing/spec directory (a.k.a. testing_spec) first step into the testing drectory and then execute rspec.
```bash
$ cd testing
$ ../bin/bundle exec rspec
```
