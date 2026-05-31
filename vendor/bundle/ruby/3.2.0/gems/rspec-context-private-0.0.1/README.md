## rspec-context-private

Writing Ruby? :thumbsup: Using RSpec? :thumbsup: Feeling naughty? :scream: Want to test some private methods? :astonished:


```ruby
# Gemfile
gem 'rspec-context-private'
```

```ruby
# example.rb
class Example
  private def foo
    'bar'
  end
end
```

```ruby
# example_spec.rb
describe Example do
  describe 'some private methods', :private do
    expect(subject.foo).to eq 'bar'
  end
end
```

### Why would you EVER!? want to test a private method?

If you're using some flavor of TDD, you might want to test some private methods that you develop along the way. Maybe you'll delete them later? Or maybe you're a crazy rebel :stuck_out_tongue_closed_eyes: and you'll keep the tests around and make your code difficult to refactor and disappoint the Internet!

Whatever your reason - this gem makes it more pleasant to test private methods.

### Credits

Written by [@barelyknown](http://twitter.com/barelyknown).

This gem uses [RSpec's shared context feature](https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-context).

The idea for the gem came from [this old blog post](http://blog.jayfields.com/2007/11/ruby-testing-private-methods.html) by Jay Fielder.
