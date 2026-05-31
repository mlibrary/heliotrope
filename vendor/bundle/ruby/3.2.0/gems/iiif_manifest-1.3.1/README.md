# IIIFManifest

Code:
[![CircleCI](https://circleci.com/gh/samvera/iiif_manifest.svg?style=svg)](https://circleci.com/gh/samvera/iiif_manifest) [![Coverage Status](https://coveralls.io/repos/github/samvera/iiif_manifest/badge.svg)](https://coveralls.io/github/samvera/iiif_manifest)

Docs:
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./CONTRIBUTING.md) [![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Community Support: [![Samvera Community Slack](https://img.shields.io/badge/samvera-slack-blueviolet)](http://slack.samvera.org/)

# What is IIIFManifest

IIIF <http://iiif.io/> defines an API for presenting related images in a viewer. This transforms Hydra::Works objects into that format usable by players such as <http://universalviewer.io/>

## Product Owner & Maintenance

`iiif_manifest` is a Core Component of the Samvera Community. The documentation for what this means can be found [here](http://samvera.github.io/core_components.html#requirements-for-a-core-component).

### Product Owner

[kdid](https://github.com/kdid)

# Usage

Your application **_must_** have an object that implements `#file_set_presenters` and `#work_presenters`. The former method should return as set of leaf nodes and the later any interstitial nodes. If none are found an empty array should be returned.

Additionally, it **_must_** have a `#description` method that returns a string.

Additionally it **_should_** implement `#manifest_url` that shows where the manifest can be found.

Additionally it **_should_** implement `#manifest_metadata` to provide an array containing hashes of metadata Label/Value pairs.

Additionally it **_may_** implement `#search_service` to contain the url for a IIIF search api compliant search endpoint and `#autocomplete_service` to contain the url for a IIIF search api compliant autocomplete endpoint. Please note, the autocomplete service is embedded within the search service description so if an autocomplete_service is supplied without a search_service it will be ignored. The IIIF `profile` added to the service descriptions is version 0 as this is the version supported by the current version of Universal Viewer. Only include a search_service within the manifest if your application has implemented a IIIF search service at the endpoint specified in the manifest.

Additionally it **_may_** implement `#sequence_rendering` to contain an array of hashes for file downloads to be offered at sequences level. Each hash must contain "@id", "format" (mime type) and "label" (eg. `{ "@id" => "download url", "format" => "application/pdf", "label" => "user friendly label" }`).

Finally, it **_may_** implement `ranges`, which returns an array of objects which represent a table of contents or similar structure, each of which responds to `label`, `ranges`, and `file_set_presenters`.

For example:

```ruby
  class Book
    def initialize(id, pages = [])
      @id = id
      @pages = pages
    end

    def file_set_presenters
      @pages
    end

    def work_presenters
      []
    end

    def manifest_url
      "http://test.host/books/#{@id}/manifest"
    end

    def description
      'a brief description'
    end

    def manifest_metadata
          [
            { "label" => "Title", "value" => "Title of the Item" },
            { "label" => "Creator", "value" => "Morrissey, Stephen Patrick" }
          ]
    end

    def search_service
      "http://test.host/books/#{@id}/search"
    end

    def autocomplete_service
      "http://test.host/books/#{@id}/autocomplete"
    end

    def sequence_rendering
      [{"@id" => "http://test.host/file_set/id/download", "format" => "application/pdf", "label" => "Download"}]
    end

    def ranges
      [
        ManifestRange.new(
          label: "Table of Contents",
          ranges: [
            ManifestRange.new(
              label: "Chapter 1",
              file_set_presenters: @pages
            )
          ]
        )
      ]
    end
  end

  class ManifestRange
    attr_reader :label, :ranges, :file_set_presenters
    def initialize(label:, ranges: [], file_set_presenters: [])
      @label = label
      @ranges = ranges
      @file_set_presenters = file_set_presenters
    end
  end
```

The class that represents the leaf nodes, must implement `#id`. It must also implement `#display_image` which returns an instance of `IIIFManifest::DisplayImage`

Additionally it **_may_** implement `#sequence_rendering` to contain an array of hashes for file downloads to be offered at each leaf node. This follows a similar format as `#sequence_rendering` at sequences level.

```ruby
  class Page
    def initialize(id)
      @id = id
    end

    def id
      @id
    end

    def display_image
      IIIFManifest::DisplayImage.new(id,
                                     width: 100,
                                     height: 100,
                                     format: "image/jpeg",
                                     iiif_endpoint: endpoint
                                     )
    end

    def sequence_rendering
      [{"@id" => "http://test.host/display_image/id/download", "format" => "application/pdf", "label" => "Download"}]
    end

    private

      def endpoint
        IIIFManifest::IIIFEndpoint.new("http://test.host/images/#{id}",
                                       profile: "http://iiif.io/api/image/2/level2.json")
      end
  end
```

Then you can produce the manifest on the book object like this:

```ruby
  book = Book.new('book-77',[Page.new('page-99')])
  IIIFManifest::ManifestFactory.new(book).to_h.to_json
```

## Presentation 3.0 (Alpha)

Provisional support for the [3.0 alpha version of the IIIF presentation api spec](https://iiif.io/api/presentation/3.0/) has been added with a focus on audiovisual content. The [change log](https://iiif.io/api/presentation/3.0/change-log/) lists the changes to the specification.

The presentation 3.0 support has been contained to the `V3` namespace. Version 2.0 manifests are still being built using `IIIFManifest::ManifestFactory` while version 3.0 manifests can now be built using `IIIFManifest::V3::ManifestFactory`.

```ruby
  book = Book.new('book-77',[Page.new('page-99')])
  IIIFManifest::V3::ManifestFactory.new(book).to_h.to_json
```

### Notable changes for Presentation 3.0

- Presenters must still define `#description` but it is now serialized as `summary`. (<https://iiif.io/api/presentation/3.0/change-log/#126-rename-description-to-summary>)
- All textual strings, including metadata labels and values, are now serialized as language maps and may be provided as a hash with language code keys with string values. Values not provided in this format are automatically converted so no change to `#description`, `#manifest_metadata`, range labels, or other fields are required. (<https://iiif.io/api/presentation/3.0/change-log/#133-use-language-map-pattern-for-label-value-summary>)
- Presenters **_may_** implement `#homepage` to contain a hash for linking back to a repository webpage for this manifest. The hash must contain "id", "format" (mime type), "type", and "label" (eg. `{ "id" => "repository url", "format" => "text/html", "type" => "Text", "label" => { "en": ["View in repository"] }`).
- File set presenters may target a fragment of its content by providing `#media_fragment` which will be appended to its `id`.
- Range objects may now implement `#items` instead of `#ranges` and `#file_set_presenters` to allow for interleaving these objects. `#items` is not required and existing range objects should continue to work.
- File set presenters may provide `#display_content` which should return an instance of `IIIFManifest::V3::DisplayContent` (or an array of instances in the case of a user `Choice`). `#display_image` is no longer required but will still work if provided.
- DisplayContent may provide `#auth_service` which should return a hash containing a IIIF Authentication service definition (<https://iiif.io/api/auth/1.0/>) that will be included on the content resource.

## Configuration

The `label`, `rights`, `homepage`, `description` (V2 only), and `summary` (V3 only) properties can be configured to pull its information from different attributes.

**NOTE:** In the V2 manifest, `label` and `description` is expected to be a string so if the model's attribute is multivalued, only the first value would be used.

To enable this, add the following code to a config file at `config/initializers/iiif_manifest_config.rb` in your application.
```ruby
  # Example: use the default configuration but amend the summary property
  IIIFManifest.config do |config|
    config.manifest_property_to_record_method_name_map.merge!(summary: :abstract, rights: :license)
  end
```
In the above example of a V3 manifest (since it is a `summary` instead of `description`), the `summary` property will be using the model's `#abstract` attribute value instead of the default `#description`. The `rights` property will use the model's `#license` attribute instead of the default `#rights_statement`. All other configurable properties will use their defaults.

```ruby
  # Example: use this configuration to set the max edge length of thumbnails, default is 200
   IIIFManifest.confg do |config|
     config.max_edge_for_thumbnail = 100
   end
```
Thumbnails have been added for version 3 manifests because [Universal Viewer](https://github.com/UniversalViewer/universalviewer/issues/102) currently require them to be explicitly set otherwise they would not show up.  The above example is used to configure what the default size for the thumbnails would be.

```ruby
# Example: use this configuration to disable thumbnails to show up by default on the manifest level (version 3 only)
  IIIFManifest.confg do |config|
    config.manifest_thumbnail = false
  end
```
According to the Presentation API 3.0 [specifications](https://iiif.io/api/presentation/3.0/#thumbnail):
> A Manifest *SHOULD* have the `thumbnail` property with at least one item.

The above configuration allows you to disable that if desired since it is not a *MUST*.


# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/samvera-labs/iiif_manifest>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

If you're working on PR for this project, create a feature branch off of `main`.

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

## Help

The Samvera community is here to help. Please see our [support guide](./SUPPORT.md).

# Acknowledgments

This software has been developed by and is brought to you by the Samvera community. Learn more at the [Samvera website](http://samvera.org/).

![Samvera Logo](https://raw.githubusercontent.com/samvera/maintenance/main/assets/samvera_tree.png)
