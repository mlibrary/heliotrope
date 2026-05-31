# HydraEditor

Code:
[![Gem Version](https://badge.fury.io/rb/hydra-editor.png)](http://badge.fury.io/rb/hydra-editor)
[![Build Status](https://circleci.com/gh/samvera/hydra-editor.svg?style=svg)](https://circleci.com/gh/samvera/hydra-editor)
[![Coverage Status](https://coveralls.io/repos/github/samvera/hydra-editor/badge.svg?branch=main)](https://coveralls.io/github/samvera/hydra-editor?branch=main)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE.txt)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is hydra-editor?

A basic metadata editor for Rails applications based on hydra-head.

## Product Owner & Maintenance

`hydra-editor` was a Core Component of the Samvera Community. Given a decline in available labor required for maintenance, this project no longer has a dedicated Product Owner. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

**Vacant**

_Until a Product Owner has been identified, we ask that you please direct all requests for support, bug reports, and general questions to the [`#dev` Channel on the Samvera Slack](https://samvera.slack.com/app_redirect?channel=dev)._

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Getting Started

To use add to your gemfile:

```ruby
gem 'hydra-editor'
```

Then run:
```
bundle install
```

Next generate the bootstrap form layouts:
```
rails generate simple_form:install --bootstrap
```

And to config/routes.rb add:

```ruby
  mount HydraEditor::Engine => '/'
```

(Note: You do not have to mount the engine if you do not intend to use the engine's default routes.)

In your initialization set ```HydraEditor.models```

```ruby
# config/initializers/hydra_editor.rb
HydraEditor.models = ["RecordedAudio", "PdfModel"]
```

You can customize the names of your fields/models by adding to your translation file:

```yaml
# config/locales/en.yml
en:
  hydra_editor:
    form:
      model_label:
        PdfModel: "PDF"
        RecordedAudio: "audio"

  simple_form:
    labels:
      image:
        dateCreated: "Date Created"
        sub_location: "Holding Sub-location"
```

Create a form object for each of your models.

```ruby
# app/forms/recorded_audio_form.rb
class RecordedAudioForm
  include HydraEditor::Form
  self.model_class = RecordedAudio
  self.terms = [] # Terms to be edited
  self.required_fields = [] # Required fields
end
```

Add the javascript by adding this line to your app/assets/javascript/application.js:

```javascript
//= require hydra-editor/hydra-editor
```

Add the stylesheets by adding this line to your app/assets/stylesheets/application.css:

```css
 *= require hydra-editor/hydra-editor
```

(Note: The Javascript includes require Blacklight and must be put after that.)

## Updating to 4.0.0

* [SimpleForm](https://github.com/plataformatec/simple_form) is supported from release 3.2.0 onwards
* `#to_model` now returns `self` (previously it was the value of `@model`):
  ```ruby
    class MyForm
      include HydraEditor::Form
      self.model_class = MyModel
      self.terms = [:title, :creator]
      # [...]
    end
    # [...]
    some_work = MyModel.new(title: ['Black holes: The Reith Lectures.'], creator: 'S.W. Hawking')
    some_form = MyForm.new(some_work)
    # [...]
    some_form.to_model
    # => #<MyForm:0x00007fd5b2fd1468 @attributes={"id"=>nil, "title"=>["Black holes: The Reith Lectures."], "creator"=>"S.W. Hawking"}, @model=#<MyModel id: nil, title: ["Black holes: The Reith Lectures."], creator: "S.W. Hawking">>
  ```
* When a form field for a single value is empty, it now returns a `nil` value (as opposed to an empty `String`):
  ```ruby
    class MyForm
      include HydraEditor::Form
      self.model_class = MyModel
      self.terms = [:title, :creator]
      # [...]
    end

    # [...]
    values = MyForm.model_attributes(
      title: ['On the distribution of values of angles determined by coplanar points.'],
      creator: ''
    )
    values['creator']
    # => nil
  ```

## Other customizations

By default `hydra-editor` provides a RecordsController with :new, :create, :edit, and :update actions implemented in the included RecordsControllerBehavior module, and a RecordsHelper module with methods implemented in RecordsHelperBehavior.  If you are mounting the engine and using its routes, you can override the controller behaviors by creating your own RecordsController:

```ruby
class RecordsController < ApplicationController
  include RecordsControllerBehavior

  # You custom code
end
```

If you are not mounting the engine or using its default routes, you can include RecordsControllerBehavior in your own controller and add the appropriate routes to your app's config/routes.rb.

## Releasing

1. `bundle install`
2. Increase the version number in `lib/hydra_editor/version.rb`
3. Increase the same version number in `.github_changelog_generator`
4. Update `CHANGELOG.md` by running this command:

  ```
  github_changelog_generator --user samvera --project hydra-editor --token YOUR_GITHUB_TOKEN_HERE
  ```

5. Commit these changes to the main branch

6. Run `rake release`

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)
