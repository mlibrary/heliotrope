Deprecation
------------
Provide deprecation warnings for code

## Add warnings
```ruby
class DeprecatedModule
  extend Deprecation
  self.deprecation_horizon = 'my_gem version 3.0.0'

  def asdf

  end
  deprecation_deprecate :asdf

  def custom_deprecation *args
    Deprecation.warn(DeprecatedModule, "don't do that!") if args.length < 15
  end

end

DeprecatedModule.new.asdf
DEPRECATION WARNING: asdf is deprecated and will be removed from my_gem version 3.0.0. (called from irb_binding at (irb):18)
=> nil

```

## Silence warnings

```ruby

  def silence_asdf_warning
     Deprecation.silence(DeprecationModule) do
       asdf
     end
  end
```

## Reporting
```ruby
Deprecation.default_deprecation_behavior = :stderr # the default

Deprecation.default_deprecation_behavior = :log # put deprecation warnings into the Rails / ActiveSupport log

DeprecationModule.debug = true # put the full callstack in the logged message

Deprecation.default_deprecation_behavior = :notify # use ActiveSupport::Notifications to log the message

Deprecation.default_deprecation_behavior = :raise # Raise an exception when using deprecated behavior

Deprecation.default_deprecation_behavior = :silence # ignore all deprecations

```
