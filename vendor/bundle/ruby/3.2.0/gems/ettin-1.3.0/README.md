# Ettin

[![Build Status](https://travis-ci.org/mlibrary/ettin.svg?branch=master)](https://travis-ci.org/mlibrary/ettin)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/ettin/badge.svg?branch=master)](https://coveralls.io/github/mlibrary/ettin?branch=master)
[![API Docs](https://img.shields.io/badge/API_docs-rubydoc.info-blue.svg)](https://www.rubydoc.info/github/mlibrary/ettin)

## Summary

Ettin manages loading and accessing settings from your configuration files,
in an environment-aware fashion. It has only a single dependency on `deep_merge`,
and provides only the functionality you actually need. It does not monkey-patch
ruby nor does it pollute the global namespace.

## Why should I use this over other options?

* Ettin has far fewer dependencies than the top configuration gems.
* Ettin does not pollute the global namespace.
* Ettin provides only the features you need; or, put another way, Ettin does
  not offer you paths that should not be followed.
* Ettin is just plain ruby. No magic. No DSL.
* Ettin works _everywhere_.

## Compatibility

* ruby 2.6.x
* ruby 2.5.x
* ruby 2.4.x
* ruby 2.3.x

As Ettin does not rely on any specific runtime environment other than
the ruby core and standard library, it is compatible with every
ruby library and framework.

## Installation

1. Add it to your bundle and install like any other gem.
2. Ettin provides an executable that will create the recommended configuration
   files for you. These files will be empty. You can also create them yourself,
   or simply specify your own files when you load Ettin.

   `bundle exec ettin -v -p some/path`

## Loading Settings

Ettin is just plain ruby. There's nothing special about the objects it
creates or how it creates them.  As such, it's up to the application to
decide how it provides access to the configuration object. That may seem
scary or confusing, but it's not--it's just plain ruby.  A few examples
are below:

Assign to a global constant using the default files:

```ruby
Settings = Ettin.for(Ettin.settings_files("config", "development"))
```

Assign with custom files:

```ruby
Settings = Ettin.for("config/path/1.yml", "config/path/2.yml")
```

Declare and assign to a top-level module:

```ruby
module MyApp
  class << self
    def config
      @config ||= Ettin.for(Ettin.settings_files("config"), ENV["MYAPP_ENV"])
    end
  end
end
```

Use one of the above variants in a Rails app's `application.rb`, making
settings available to your `environment.rb`, `development.rb`, and initializers:

```ruby
module MyApp
  class << self
    def config
      @config ||= Ettin.for(Ettin.settings_files("config", Rails.env))
    end
  end

  class Application < Rails::Application
    # ...
  end
end
```

Add a section to the Rails configuration in an initializer (noting that load
order is alphanumeric):

```ruby
Rails.application.configure do |config|
  config.settings = Ettin.for(...)
end
```


## Default / Recommended Configuration Files

The provided ettin executable will create the following files,
including a file for each environment of production, development,
and test.

The name of the environment is not special, so you can easily create more.

    config/settings.yml
    config/settings/#{environment}.yml

    config/settings.local.yml
    config/settings/#{environment}.local.yml

Environment-specific settings take precedence over common, and the .local
files take precedence over those. The local files are intendended to be gitignored.

Ettin will also read from the following files commonly placed by other config gems.
However, inclusion of these files is redundant, and can be confusing. Their inclusion
is not recommended.

    config/environments/#{environment}.yml
    config/environments/#{environment}.local.yml

## Using the Settings

### Access

Entries are available via dot-notation:

```ruby
config.some_setting               #=> 5
config.some.nested.setting        #=> "my nested string"
```

...or `[]` notation:

```ruby
config[:some_setting]             #=> 5
config["some_setting"]            #=> 5
config[:some][:nested][:setting]  #=> "my nested string"
```

When a setting is not present, the returned value will be `nil`. We find
that this is what most people expect. If you'd like an exception to be
thrown, you can use dot-notation with a bang added:


```ruby
config.some_missing_setting!      #=> raises a KeyError
```

### Assignment

You can also change settings at runtime via a merge:

```ruby
config.some_setting               #=> 5
config.merge!({some_setting: 22})
config.some_setting               #=> 22
```

...or direction assignment:


```ruby
config.some_setting               #=> 5
config.some_setting = 22
config.some_setting               #=> 22
```

Both of these methods work for any level of nesting.


### ERB

In Ettin, YAML files support ERB by default.


```ruby
# in settings.yml

redis:
  hostname: <%= ENV["REDIS_HOST"] %>
```

### Environment-specific Configuration Files

Environment-specific configuration files are supported. These files
take precedence over the common configuration, as you'd expect.  The

## FAQs

### How can I reload the entire setting object?

Ettin's settings object is just a plain ruby object, so you should simply
assign your settings reference to something else.

### Why these specific files?

Ettin is designed to be an easy transition from users of
[config](https://github.com/railsconfig/config). We also think that these
locations are quite sensible.

### How do I validate my settings?

Validation is a concern that is driven by the application itself. Placing the
responsibility for that validation in Ettin would violate the single-responsibility
principle. You should validate the settings where they're used, such as in an
initialization step.

### How do I load environment variables into my settings?

Just use ERB. See the
[ERB docs](http://ruby-doc.org/stdlib-2.4.2/libdoc/erb/rdoc/ERB.html)
for more information.

### How can I pull in settings from another source?

Ettin supports hashes and paths to yaml files out of the box. You can extend
this support by creating a subclass of `Ettin::Source`. Your subclass will
need to define `::handles?(target)`, make a call of `register(self)`, and
define a `#load` method that returns a hash.


## Authors

* This project was inspired by [railsconfig](https://github.com/railsconfig/config).
* The author and maintainer is [Bryan Hockey](https://github.com/malakai97)

## License

    Copyright (c) 2018 The Regents of the University of Michigan.
    All Rights Reserved.
    Licensed according to the terms of the Revised BSD License.
    See LICENSE.md for details.

