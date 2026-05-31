# Canister

[![Build Status](https://travis-ci.org/mlibrary/canister.svg?branch=master)](https://travis-ci.org/mlibrary/canister)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/canister/badge.svg?branch=master)](https://coveralls.io/github/mlibrary/canister?branch=master)
[![API Docs](https://img.shields.io/badge/API_docs-rubydoc.info-blue.svg)](https://www.rubydoc.info/github/mlibrary/canister)

## Summary

Canister is a simple IoC container for ruby. It has no dependencies and provides only
the functionality you need. It does not monkey-patch ruby or pollute the global
namespace, and most importantly *it expects to be invisible to your domain classes.*

It provides:

* Out-of-order declaration
* Caching
* Automatic dependency resolution
* Automatic cache invalidation on re-registration

## Why do I need this? Especially in ruby?

Canister was created to make it easier to declare the setup for an application's
production and test environments in a single place, without needing to know
when exactly those objects were created.

*Canister is not a replacement for
dependency injection.* Rather, it is useful when you have designed your objects
to have their dependencies injected.

The domain of your application is not concerned with the design
patterns you use to implement it; therefore, the domain entities within in it should
represent the domain, not the patterns.
For example, it would be a *mistake* to write all of your classes such that they
accept a single parameter called `container`.  `Car.new(container)` is undesirable
when what your application really calls for is `Car.new(make, model, year)`.

For more information on dependency injection and inversion of control containers in
ruby, please see
[this excellent article](https://gist.github.com/malakai97/b1d3bdf6d80c6f99a875930981243f9d)
by [Jim Weirich](https://en.wikipedia.org/wiki/Jim_Weirich) that both sums up the issue
and was the inspiration for this gem.


## Installation

Add it to your Gemfile and you're off to the races.

## Usage

```ruby
# Basic usage
container = Canister.new
container.register(:foo) { "foo" }
container.register(:bar) {|c| c.foo + "bar" }

container.bar     #=> "foobar"
container[:bar]   #=> "foobar"
container["bar"]  #=> "foobar"

# Dependencies can be declared in any order
container.register(:after) {|c| "#{c.before} and after" }
container.register(:before) { "before" }
container.after   #=> "before and after"

# Values are cached
container.register(:wait) { sleep 3; 27 }
container.wait
  .
  .
  .
  #=================> 27
container.wait    #=> 27

# Caches are invalidated automatically
container.register(:foo) { "oof" }
container.bar     #=> "oofbar"
```

## Contributing

Standard rules apply.

## Compatibility

Canister has been tested on the following:

* ruby >= 2.3.x
* ruby >= 3.x
* jruby 9.4.2.0 (3.1.0)

As Canister does not rely on any specific runtime environment other than
the ruby core, it is compatible with every ruby library and framework.

## Authors

* The author and maintainer is [Bryan Hockey](https://github.com/malakai97)
* This project was inspired by
  [this excellent article](https://gist.github.com/malakai97/b1d3bdf6d80c6f99a875930981243f9d)
  by [Jim Weirich](https://en.wikipedia.org/wiki/Jim_Weirich). (We are not affiliated, so
  don't blame him if this breaks.)

## License

    Copyright (c) 2018 The Regents of the University of Michigan.
    All Rights Reserved.
    Licensed according to the terms of the Revised BSD License.
    See LICENSE.md for details.

