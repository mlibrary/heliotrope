[![Tests](https://github.com/mlibrary/keycard/actions/workflows/test.yml/badge.svg)](https://github.com/mlibrary/keycard/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/keycard/badge.svg?branch=main)](https://coveralls.io/github/mlibrary/keycard?branch=main)
[![User Docs](https://img.shields.io/badge/user_docs-readthedocs-blue.svg)](https://keycard.readthedocs.io/en/latest)
[![API Docs](https://img.shields.io/badge/API_docs-rubydoc.info-blue.svg)](https://www.rubydoc.info/gems/keycard)

# Keycard

Keycard provides authentication support and user/request information, especially
in Rails applications.

Keycard is designed to give you sound guidelines and integration between
authentication and authorization without constraining your application. It
takes inspiration from [Sorcery](https://github.com/Sorcery/sorcery), but has
four important distinctions:

1. It does not use mixins to configure a "model that can log in".
2. It provides a way to retrieve user and session attributes like directory
   information or IP address-based region, rather than being strictly about
   logging in and out.
3. It only provides one built-in strategy for logins, focused on single sign-on
   scenarios.
4. It offers an optional group implementation for whatever objects your
   application manages as accounts or users.

The ultimate goal is to provide useful tools that integrate easily and simplify
building applications that have clean, well-factored designs. Keycard should
help you focus on solving your application problems, while remaining invisible
-- not magical -- to most of your application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keycard'
```

And then execute:

    $ bundle

## Configuration

There are two aspects of Keycard that are configurable: the database for IP
ranges as they map to institutions (IP blocks map to networks, and networks are
associated with institutions), and the access mode (whether your application is
served directly or behind a reverse proxy). These will be unified eventually,
but for now, they are configured separately.

### For the Database

For the database, there is a Railtie that, when running in a Rails app,
attempts to use the same connection information as ActiveRecord. If you are
running in this configuration, you will need to run a `rake db:migrate` to
create the Keycard tables and add them to your `db/schema.rb`. From there forward,
running `db:setup` or `db:schema:load` will create these tables for you. There is
a `keycard:migrate` Rake task if you want to run it separately, but it hooks into
the Rails `db:migrate` by default for convenience.

If you need to customize the database configuration, which will be typical for
at least the production environment, the easiest way is to define an
initializer. In a multi-application environment, the database may be read-only,
which will require the `Keycard::DB.config` to have its `readonly` property set
to `true`. You can also set either the `Keycard::DB.config.opts` to the options
to pass to the Sequel connection or set `Keycard::DB.config.url` to use a
connction string. The latter is equivalent to setting the `KEYCARD_DATABASE_URL`
environment variable.

### For the Access Mode

To extract the username and client IP from each request, Keycard must be
configured for an "access mode". This can be set in an initializer, under the
`Keycard.config.access` property, and should be either `:direct` if clients
will make HTTP requests directly to the Ruby webserver, or `:proxy` if a
reverse proxy will be used.

Under the hood, these modes amount to using either `REMOTE_USER` and
`REMOTE_ADDR` in the environment set by the Ruby webserver for direct mode or
the `X-Forwarded-User` and `X-Forwarded-For` headers set by a reverse proxy.

## Compatibility

Keycard is intended to be compatible with all community-supported Ruby branches (i.e., minor versions), currently:

 - 3.2
 - 3.3
 - 3.4
 - 4.0

We prefer the newest syntax and linting rules that preserve compatibility with the oldest branch in normal maintenance.
When the security maintenance for a branch expires, Keycard's compatibility should be considered unsupported.

See also, [Ruby's branch maintenance policy](https://www.ruby-lang.org/en/downloads/branches/).

## License

Keycard is licensed under the BSD-3-Clause license. See [LICENSE.md](LICENSE.md).
