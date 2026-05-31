[![Tests](https://github.com/mlibrary/checkpoint/actions/workflows/test.yml/badge.svg)](https://github.com/mlibrary/checkpoint/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/checkpoint/badge.svg?branch=main)](https://coveralls.io/github/mlibrary/checkpoint?branch=main)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![User Docs](https://img.shields.io/badge/user_docs-readthedocs-blue.svg)](https://checkpoint.readthedocs.io/en/latest)
[![API Docs](https://img.shields.io/badge/API_docs-rubydoc.info-blue.svg)](https://www.rubydoc.info/gems/checkpoint)

# Checkpoint

Checkpoint provides a model and infrastructure for policy-based authorization,
especially in Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'checkpoint'
```

And then execute:

    $ bundle

## Compatibility

Checkpoint is intended to be compatible with all community-supported Ruby branches (i.e., minor versions), currently:

 - 3.2
 - 3.3
 - 3.4
 - 4.0

We prefer the newest syntax and linting rules that preserve compatibility with the oldest branch in normal maintenance.
When the security maintenance for a branch expires, Checkpoint's compatibility should be considered unsupported.

See also, [Ruby's branch maintenance policy](https://www.ruby-lang.org/en/downloads/branches/).

## Documentation

User documentation source is available in the `docs` directory and in rendered format
on [readthedocs](https://checkpoint.readthedocs.io/en/latest/).

API/class documentation is in YARD format and in rendered format on [rubydoc.info](https://www.rubydoc.info/gems/checkpoint).

## License

Checkpoint is licensed under the BSD-3-Clause license. See [LICENSE.md](LICENSE.md).
