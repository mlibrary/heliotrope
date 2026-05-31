resque-web
==========
[![Gem Version](http://img.shields.io/gem/v/resque-web.svg)](https://rubygems.org/gems/resque-web)
[![Build Status](https://img.shields.io/travis/resque/resque-web.svg)](https://travis-ci.org/resque/resque-web)
[![Dependency Status](https://img.shields.io/gemnasium/resque/resque-web.svg)](https://gemnasium.com/resque/resque-web)
[![Code Climate](https://img.shields.io/codeclimate/github/resque/resque-web.svg)](https://codeclimate.com/github/resque/resque-web)
[![Coverage Status](https://img.shields.io/coveralls/resque/resque-web/master.svg)](https://coveralls.io/r/resque/resque-web)

A Rails-based frontend to the [Resque](https://github.com/resque/resque) job
queue system. This provides a similar interface to the existing Sinatra
application that comes bundled with Resque, but deploys like a Rails application
and leverages Rails conventions for factoring things like controllers, helpers,
and views.

# NOTICE
Note this is NOT the old sinatra interface that comes with Resque 1-x. This is
a new project based on rails. If you have any issues with old web server,
please file an issue on the [resque](https://github.com/resque/resque) project.
Note that the sinatra web interface will be gone in Resque 2.0 and this is
meant to be the replacement.

More documentation coming soon!

## Starting
Resque web is built as a rails engine.

Add it to your gemfile.

```Ruby
gem 'resque-web', require: 'resque_web'
```

Mount it in your config/routes.rb.

```Ruby
require "resque_web"

MyApp::Application.routes.draw do
  mount ResqueWeb::Engine => "/resque_web"
end
```

If `RAILS_RESQUE_REDIS` is set in `ENV` and is not the empty string, this gem will set `Resque.redis` equal to `ENV['RAILS_RESQUE_REDIS']` in an initializer.

If you need to set a password for your redis server, use this env variable.
```
RAILS_RESQUE_REDIS_PASSWORD=secure_pass
```

For info on configuring Resque itself (and accepted values of `Resque.redis`) see [the Configuration section of the Resque README](https://github.com/resque/resque#configuration).


## Security

You almost certainly want to limit access when using resque-web in production. Using [routes constraints](http://guides.rubyonrails.org/routing.html#request-based-constraints) is one way to achieve this:

```ruby
# config/routes.rb

resque_web_constraint = lambda { |request| request.remote_ip == '127.0.0.1' }
constraints resque_web_constraint do
  mount ResqueWeb::Engine => "/resque_web"
end

```

Another example of a route constraint using the current user when using Devise or another warden based authentication system:

```ruby
# config/routes.rb
resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  current_user.present? && current_user.respond_to?(:is_admin?) && current_user.is_admin?
end

constraints resque_web_constraint do
  mount ResqueWeb::Engine => "/resque_web"
end

```

### HTTP Basic Authentication

HTTP Basic Authentication is supported out of the box. Simply set the environment variables `RESQUE_WEB_HTTP_BASIC_AUTH_USER` and `RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD` to turn it on. If you're using Resque with Heroku run `heroku config:set RESQUE_WEB_HTTP_BASIC_AUTH_USER=user RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD=secret` to get ResqueWeb secured.

## Plugins

In the past with the sinatra app it was fairly simple to just monkey-patch the
server to add more functionality/tabs. With this rails version you have to write
an engine under a specific namespace. Read more in PLUGINS.md.

## Existing plugins

- https://github.com/mattgibson/resque-scheduler-web

## Screenshot

![Screenshot](http://i.imgur.com/LkNgl.png)

## Developing

We use [Appraisal](https://github.com/thoughtbot/appraisal) to test gem across multiple rails version.

To run tests locally you need to install generic dependencies and dependencies for each appraisal version by running:

```
bundle install
appraisal install
```

And then you can use following command for testing lib with latest rails version 5.0:

```
appraisal rails50 rake test
```

If you want to run tests for all rails version like Travis do check out this library: (WWTD)[https://github.com/grosser/wwtd].
