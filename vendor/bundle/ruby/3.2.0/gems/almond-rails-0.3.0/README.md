# Almond for Rails

## Usage
In your Gemfile:

```ruby
gem 'almond-rails'
```

Then add to `app/assets/javascripts/application.js`:

```javascript
//= require almond 
```

Then you can use the `require` method in your es6 javascript:

```javascript
var module = require('path/to/module/my_class')
new module.MyClass()
```
