# ldp (Linked Data Platform)

Code:
[![Gem Version](https://badge.fury.io/rb/ldp.png)](http://badge.fury.io/rb/ldp)
[![Build Status](https://circleci.com/gh/samvera/ldp.svg?style=svg)](https://circleci.com/gh/samvera/ldp)
[![Coverage Status](https://coveralls.io/repos/github/samvera/ldp/badge.svg?branch=main)](https://coveralls.io/github/samvera/ldp?branch=main)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is `ldp`?

[Linked Data Platform](https://www.w3.org/TR/ldp/) client library for Ruby

## Product Owner & Maintenance

`ldp` is a Core Component of the Samvera Community. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[randalldfloyd](https://github.com/randalldfloyd)

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

## Installation

Add this line to your application's Gemfile:

    gem 'ldp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ldp

## Usage

```ruby
host = 'http://localhost:8080'
client = Ldp::Client.new(host)
resource = Ldp::Resource.new(client, host + '/rest/node/to/update')
orm = Ldp::Orm.new(resource)

# view the current title(s)
orm.orm.value(RDF::DC11.title)

# update the title
orm.graph.delete([orm.resource.subject_uri, RDF::DC11.title, nil])
orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, 'a new title'])

# save changes
orm.save
```
## Contributing 

If you're working on PR for this project, create a feature branch off of `main`. 

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/main/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `main` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

## Testing:

- Set Rails version you want to test against. For example:

  - `export RAILS_VERSION=5.1.4`

- Ensure that the correct version of Rails is installed: `bundle update`

- And run tests: `bundle exec rake rspec`

## Releasing

1. `bundle install`
2. Increase the version number in `lib/ldp/version.rb`
3. Increase the same version number in `.github_changelog_generator`
4. Update `CHANGELOG.md` by running this command:
  ```
  github_changelog_generator --user samvera --project ldp --token YOUR_GITHUB_TOKEN_HERE
  ```
5. Commit these changes to the main branch
6. Run `rake release`

# Acknowledgments
This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org)

![Samvera Logo](https://raw.githubusercontent.com/samvera/maintenance/main/assets/samvera_tree.png)
