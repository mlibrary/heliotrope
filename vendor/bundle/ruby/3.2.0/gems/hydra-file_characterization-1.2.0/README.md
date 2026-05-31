# hydra-file_characterization

Code:
[![Gem Version](https://badge.fury.io/rb/hydra-file_characterization.png)](http://badge.fury.io/rb/hydra-file_characterization)
[![Build Status](https://circleci.com/gh/samvera/hydra-file_characterization.svg?style=svg)](https://circleci.com/gh/samvera/hydra-file_characterization)
[![Coverage Status](https://coveralls.io/repos/github/samvera/hydra-file_characterization/badge.svg?branch=main)](https://coveralls.io/github/samvera/hydra-file_characterization?branch=main)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is hydra-file_characterization?

Provides a wrapper for file characterization.

# Supported versions

This software is currently tested against: 
* FITS 1.4.1
* Ruby 2.6, 2.7, and 3.0
* Rails 6.0, 6.1, and 7.0

## Product Owner & Maintenance

`hydra-file_characterization` was a Core Component of the Samvera Community. Given a decline in available labor required for maintenance, this project no longer has a dedicated Product Owner. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

**Vacant**

_Until a Product Owner has been identified, we ask that you please direct all requests for support, bug reports, and general questions to the [`#dev` Channel on the Samvera Slack](https://samvera.slack.com/app_redirect?channel=dev)._

# Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Getting Started

If you are using Rails add the following to an initializer (./config/initializers/hydra-file_characterization_config.rb):

```ruby
Hydra::FileCharacterization.configure do |config|
  config.tool_path(:fits, '/path/to/fits')
end
```

```ruby
Hydra::FileCharacterization.characterize(File.read(filename), File.basename(filename), :fits)
```

- Why `file.read`? To highlight that we want a string. In the case of ActiveFedora, we have a StringIO instead of a file.
- Why `file.basename`? In the case of Fits, the characterization takes cues from the extension name.

You can call a single characterizer...

```ruby
xml_string = Hydra::FileCharacterization.characterize(File.read("/path/to/my/file.rb"), 'file.rb', :fits)
```

...for this particular call, you can specify custom fits path...

```ruby
xml_string = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits) do |config|
  config[:fits] = './really/custom/path/to/fits'
end
```

...or even make the path callable...

```ruby
xml_string = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits) do |config|
  config[:fits] = lambda {|filename| … }
end
```

...or even create your custom characterizer on the file...

```ruby
xml_string = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :my_characterizer) do |config|
  config[:my_characterizer] = lambda {|filename| … }
end
```

You can also call multiple characterizers at the same time.

```ruby
fits_xml, ffprobe_xml = Hydra::FileCharacterization.characterize(contents_of_a_file, 'file.rb', :fits, :ffprobe)
```

## Registering New Characterizers

This is possible by adding a characterizer to the `Hydra::FileCharacterization::Characterizers` namespace.

## Contributing 

Running the tests: 
* Install FITS v1.4.1, which is the most recent version we've tested against.
```
mkdir ~/fits
wget "https://github.com/harvard-lts/fits/releases/download/1.4.1/fits-1.4.1.zip"
unzip -d ~/fits/ "fits-1.4.1.zip"
chmod a+x ~/fits/fits.sh
ln -s ~/fits/fits.sh ~/fits/fits
rm "fits-1.4.1.zip"
```

* Once FITS is installed, you should be able to run the tests with: `rspec spec`


If you're working on PR for this project, create a feature branch off of `main`. 

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

## Releasing

1. `bundle install`
2. Increase the version number in `lib/hydra/file_characterization/version.rb`
3. Increase the same version number in `.github_changelog_generator`
4. Update `CHANGELOG.md` by running this command:

  ```
  github_changelog_generator --user samvera --project hydra-file_characterization --token YOUR_GITHUB_TOKEN_HERE
  ```

5. Commit these changes to the master branch
6. Run `rake release`

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community. Learn more at the [Samvera website](http://samvera.org/).

![Samvera Logo](https://samvera.org/wp-content/uploads/2017/06/samvera-logo-tm.svg)
