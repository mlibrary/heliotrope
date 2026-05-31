# JSON-LD Preloaded
JSON-LD with preloaded contexts.

[![Gem Version](https://badge.fury.io/rb/json-ld-preloaded.png)](https://badge.fury.io/rb/json-ld-preloaded)
[![Build Status](https://github.com/ruby-rdf/json-ld-preloaded/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/json-ld-preloaded/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/json-ld-preloaded/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/json-ld-preloaded?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Features

This gem uses the preloading capabilities in `JSON::LD::Context` to create ruby context definitions for common JSON-LD contexts to dramatically reduce processing time when any preloaded context is used in a JSON-LD document. As a consequence, changes made to these contexts after the gem release will not be loaded.

Contexts are taken from https://github.com/json-ld/json-ld.org/wiki/existing-contexts:

* [Linked Open Vocabularies (LOV)](https://lov.linkeddata.es/dataset/lov/)
 * http://lov.linkeddata.es/dataset/lov/context
* [Schema.org](http://schema.org)
 * http://schema.org (needs content negotiation)
* [Hydra](http://www.hydra-cg.com/spec/latest/core/)
 * http://www.w3.org/ns/hydra/core
* [LDP](http://www.w3.org/2012/ldp/wiki/Main_Page)
 * [work in progress](http://lists.w3.org/Archives/Public/public-linked-json/2014Jul/0050.html)
* [ActivityStreams 2.0](http://activitystrea.ms)
 *  http://asjsonld.mybluemix.net/
* Open Badges (OBI)
 * https://openbadgespec.org/v1/context.json
 * issues: https://github.com/openbadges/openbadges-specification/issues
* [vCard Ontology](http://www.w3.org/TR/vcard-rdf/)
 * http://www.w3.org/2006/vcard/ns (needs content negotiation)
* [FOAF](http://xmlns.com/foaf/spec/)
 * http://xmlns.com/foaf/context
* [GeoJSON-LD](https://github.com/geojson/geojson-ld)
 * https://raw.githubusercontent.com/geojson/geojson-ld/master/contexts/geojson-base.jsonld
* [IIIF Image API](http://iiif.io/api/image/2/)
 * http://iiif.io/api/image/2/context.json
* [IIIF Presentation API](http://iiif.io/api/presentation/2/)
 * http://iiif.io/api/presentation/2/context.json
* [RDFa Core Initial Context](http://www.w3.org/2011/rdfa-context/rdfa-1.1)
 * http://www.w3.org/2013/json-ld-context/rdfa11
* [Web Payments](https://web-payments.org/)
 * multiple, see specs
* [package.json](https://github.com/digitalbazaar/jsonld.js/issues/39)
* [Research Object Bundle](https://w3id.org/bundle)
 * https://w3id.org/bundle/context
* [prefix.cc](http://prefix.cc)
 * http://prefix.cc/context (and subsets using URLs of the form http://prefix.cc/foaf,rdf,rdfs.file.jsonld)
* CultureGraph EntityFacts
 * http://hub.culturegraph.org/entityfacts/context/v1/entityfacts.jsonld
* [RDF Data Cube](http://purl.org/linked-data/cube#)
 * http://pebbie.org/context/qb
* [CSVW Namespace Vocabulary Terms](https://www.w3.org/TR/tabular-data-model/)
 * https://www.w3.org/ns/csvw

## Dependencies
* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [JSON::LD](https://rubygems.org/gems/json-ld) (>= 3.2)

## Mailing List
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributing
* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `json-ld.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Ruby]:             https://ruby-lang.org/
[RDF]:              https://www.w3.org/RDF/
[YARD]:             https://yardoc.org/
[YARD-GS]:          https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[RDF.rb]:           https://rubygems.org/gems/rdf
[Backports]:        https://rubygems.org/gems/backports
[JSON-LD]:          https://www.w3.org/TR/json-ld11/ "JSON-LD 1.1"
[Promises]:         http://dom.spec.whatwg.org/#promises
[jsonlint]:         https://rubygems.org/gems/jsonlint
