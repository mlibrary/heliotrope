# BlacklightOaiProvider
OAI-PMH service endpoint for Blacklight applications

## Description
The BlacklightOaiProvider plugin provides an [Open Archives Initiative Protocol for Metadata Harvesting (OAI-PMH)](http://www.openarchives.org/pmh/) data provider endpoint, using the [ruby-oai gem](https://github.com/code4lib/ruby-oai). This endpoint enables service providers harvest a data provider's metadata.

### Versioning
Starting `v4.1` major plugin versions are synced with major Blacklight versions. The last known version to work with Blacklight 3.x/Rails 3.x is `v0.1.0`.

A few maintenance branches have been left in place in case there is interest to add support for older versions of Rails/Blacklight:

`v3.x` -> Support for Blacklight 3.0

`v4.x` -> Support for Blacklight 4.0 and Rails 3.0

`release-5.x` -> Support for Blacklight 5.x

`release-6.x` -> Support for Blacklight 6.x

`release-7.x` -> Support for Blacklight 7.x

## Requirements
A Rails app running Rails 6.x and Blacklight 7.x.

OAI-PMH requires a timestamp field for all records. The Solr index should include an appropriate field. This field should be able to support date range queries. By default, the name of this field is `timestamp` (more on how to configure this [below](#solrdocument-configuration)).

A properly configured documentHandler in the blacklight/solr configuration.

## Installation

Add

```ruby
    gem 'blacklight_oai_provider'
```

to your Gemfile and run `bundle install`.

Then run
```ruby
rails generate blacklight_oai_provider:install
```
to install the appropriate extensions into your `CatalogController` class, `SolrDocument` class, and routes file. If you want to do customize the way this installs, instead you may:

- add this to the SolrDocument model:
```ruby
include BlacklightOaiProvider::SolrDocument
```
- add this to the Controller:
```ruby
include BlacklightOaiProvider::Controller
```
- add this to `config/routes.rb`
```ruby
  concern :oai_provider, BlacklightOaiProvider::Routes.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider
    ...
  end
```

## Configuration

While the plugin provides some sensible (albeit generic) defaults out of the box, you probably will want to customize the OAI provider configuration.

### Blacklight configuration
You can provide OAI-PMH provider parameters by placing the following in your blacklight configuration (most likely in `app/controllers/catalog_controller.rb`)

```ruby
configure_blacklight do |config|

  # ...

  config.oai = {
    provider: {
      repository_name: 'Test',
      repository_url: 'http://localhost/catalog/oai',
      record_prefix: 'oai:test',
      admin_email: 'root@localhost',
      sample_id: '109660'
    },
    document: {
      limit: 25,            # number of records returned with each request, default: 15
      set_fields: [        # ability to define ListSets, optional, default: nil
        { label: 'language', solr_field: 'language_facet' }
      ]
    }
  }

  # ...
end
```

The "provider" configuration is documented as part of the ruby-oai gem at https://github.com/code4lib/ruby-oai and can be lambdas for dynamic configuration (e.g. `repository_name: ->(controller) { controller.send(:repository_name) }`).

A basic set model is included that maps Solr fields to OAI sets. Provide `set_fields` with an array of hashes defining the solr_field, and optionally a label and description. The configuration above will cause the `ListSets` verb to query Solr for unique values of the `language_facet` field and present each value as a set using a spec format of `language:value`. When the `set` parameter is supplied to the `ListRecords` verb, it will append a filter to the Solr query of the form `fq=language_facet:value`. If no label is provided, the set will use the `solr_field` name. To customize the ListSet implementation, see [customizing listsets](#customizing-listsets).

_Note:_ The document handler in your blacklight controller must be configured properly for this plugin to correctly look up records.

### SolrDocument configuration
To change the name of the timestamp solr field in your `SolrDocument` model change the following attribute:
```ruby
self.timestamp_key = 'record_creation_date' # Default: 'timestamp'
```

The metadata displayed in the xml serialization of each record is based off the `field_semantics` hash in the `SolrDocument` model. To update/change these fields add something like the following to your model:

```ruby
  field_semantics.merge!(
    creator: "author_display",
    date: "pub_date",
    subject: "subject_topic_facet",
    title: "title_display",
    language: "language_facet",
    format: "format"
  )
```
The fields used by the dublin core serialization are:
```ruby
[:contributor, :coverage, :creator, :date, :description, :format, :identifier, :language, :publisher, :relation, :rights, :source, :subject, :title, :type]
```

### Customizing ListSets
In order to customize the default ListSets implementation, first create your own `Sets` class that subclasses `BlacklightOaiProvider::Set` or `BlacklightOaiProvider::SolrSet` and implement all required methods. Ex:
```ruby
class NewListSet < BlacklightOaiProvider::SolrSet
  def description
    "This is a #{label} set containing records with the value of #{value}."
  end
end
```

Next, your `SolrDocument` model must override, `sets`, an instance method that returns an array of sets for each document. Ex:
```ruby
def sets
  NewListSet.sets_for(self)
end
```

Finally, you can substitute you own Set model using the `set_model` option.
```ruby
config.oai = {
  document: {
    set_model: NewListSet,
    set_fields: [
      { label: 'language', solr_field: 'language_facet' }
    ]
  }
}
```

### Disable pretty print stylesheet

By default, this gem pretty prints results in the browser using an XSLT stylesheet. You can change this behavior by overriding this stylesheet with a custom stylesheet containing an identity transform. In your app, create a file named `app/assets/stylesheets/blacklight_oai_provider/oai2.xsl` containing the following XSLT:

```xml
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/ | @* | node()">
  <xsl:copy>
    <xsl:apply-templates select="@* | node()" />
  </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
```

## Tests
We use `engine_cart` and `solr_wrapper` to run tests on a dummy instance of an app using this plugin.

To run the entire test suite:
```ruby
rake ci
```

You can test OAI-PMH conformance against http://www.openarchives.org/data/registerasprovider.html#Protocol_Conformance_Testing or browse the data at http://re.cs.uct.ac.za/
