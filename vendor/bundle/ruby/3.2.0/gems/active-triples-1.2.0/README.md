Description
-----------

[![Pipeline Status](https://gitlab.com/no_reply/ActiveTriples/badges/develop/pipeline.svg)](https://gitlab.com/no_reply/ActiveTriples/commits/develop)
[![Coverage Report](https://gitlab.com/no_reply/ActiveTriples/badges/develop/coverage.svg)](https://gitlab.com/no_reply/ActiveTriples/commits/develop)
[![Gem Version](https://badge.fury.io/rb/active-triples.svg)](http://badge.fury.io/rb/active-triples)

An ActiveModel-like interface for RDF data. Models graphs as RDFSources with property/attribute configuration, accessors, and other methods to support Linked Data in a Ruby/Rails enviornment. See [RDF Concepts and Abstract Syntax](http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/#change-over-time) for an informal definition of an RDF Source.

This library was extracted from work on [ActiveFedora](https://github.com/projecthydra/active_fedora). It is closely related to (and borrows some syntax from) [Spira](https://github.com/ruby-rdf/spira), but does some important things differently.

Installation
------------

Add `gem "active-triples"` to your Gemfile and run `bundle`.

Or install manually with `gem install active-triples`.

Defining RDFSource Models
-------------------------

The core module of `ActiveTriples` is `ActiveTriples::RDFSource`. You can use this module as a mixin to create ActiveModel-like classes that represent an RDF resource as a stateful entity represented by an `RDF::Graph`. `RDFSource` implements the `RDF::Resource` interface, as well as `RDF::Queryable`, `RDF::Enumerable`, and `RDF::Mutable`. This means you can manipulate them by adding or deleting statements, query, serialize, and load arbitrary RDF.


```ruby
require 'rdf/vocab'

class Thing
  include  ActiveTriples::RDFSource

  configure type: RDF::OWL.Thing, base_uri: 'http://example.org/things#'

  property :title,       predicate: RDF::Vocab::DC.title
  property :description, predicate: RDF::Vocab::DC.description
end

obj             = Thing.new('123')
obj.title       = 'Resource'
obj.description = 'A resource.'

obj.dump :ntriples # => "<http://example.org/things#123> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .\n<http://example.org/things#123> <http://purl.org/dc/terms/title> \"Resource\" .\n<http://example.org/things#123> <http://purl.org/dc/terms/description> \"A resource.\" .\n"
```

URI and bnode values are built out as generic Resources when accessed. A more specific model class can be configured on individual properties.

```ruby
Thing.property :creator, predicate: RDF::Vocab::DC.creator, class_name: 'Person'

class Person
  include  ActiveTriples::RDFSource

  configure type:     RDF::Vocab::FOAF.Person,
            base_uri: 'http://example.org/people#'

  property :name, predicate: RDF::Vocab::FOAF.name
end

obj_2         = Thing.new('2')
obj_2.creator = Person.new

obj_2.creator
# => [#<Person:0x3fbe84ac9234(default)>]

obj_2.creator.first.name = 'Herman Melville'

obj_2.dump :ntriples # => "_:g47361345336040 <http://xmlns.com/foaf/0.1/name> \"Herman Melville\" .\n_:g47361345336040 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .\n<http://example.org/things#2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .\n<http://example.org/things#2> <http://purl.org/dc/terms/creator> _:g47361345336040 .\n"
```

Open Model
-----------

An RDFSource lets you handle data as a graph, independent of whether it is defined in the model. This is important for working in a Linked Data context, where you will want access to data you may not have known about when your models were written.

```ruby
related = Thing.new

related << RDF::Statement(related, RDF::Vocab::DC.relation, obj)
related << RDF::Statement(related, RDF::Vocab::DC.subject, 'ActiveTriples')

related.query(subject:   related,
              predicate: RDF::Vocab::DC.relation).each_statement do |s,p,o|
  puts o
end
# => http://example.org/things#123

related.query(subject:   related,
              predicate: RDF::Vocab::DC.subject).each_statement do |s,p,o|
  puts o
end
# => 'ActiveTriples'
```

Any operation you can run against an RDF::Graph works with RDFSources, too. Or you can use generic setters and getters with URI predicates:

```ruby
related.set_value(RDF::Vocab::DC.relation, obj)
related.set_value(RDF::Vocab::DC.subject,  'ActiveTriples')

related.get_values(RDF::Vocab::DC.relation)
# => [#<Thing:0x3f949c6a2294(default)>]

related.get_values(RDF::Vocab::DC.subject)
# => ["ActiveTriples"]
```

Some convienience methods provide support for handling data from web sources:
  * `fetch` loads data from the RDFSource's #rdf_subject URI
  * `rdf_label` queries across common (& configured) label fields and returning the best match

```ruby
require 'linkeddata' # to support various serializations

uri = 'http://dbpedia.org/resource/Oregon_State_University'

osu = ActiveTriples::Resource.new uri
osu.fetch

osu.rdf_label
# => ["Oregon State University", "Oregon State University", "Université d'État de l'Oregon", "Oregon State University", "Oregon State University", "オレゴン州立大学", "Universidad Estatal de Oregón", "Oregon State University", "俄勒岡州立大學", "Universidade do Estado do Oregon"]
```

Typed Data
-----------

Typed literals are handled natively through Ruby types and [RDF::Literal](https://github.com/ruby-rdf/rdf/tree/develop/lib/rdf/model/literal). There is no need to register a specific type for a property, simply pass the setter the appropriate typed data. See the examples in the RDF::Literal documentation for futher information about supported datatypes.

```ruby
Thing.property :date, predicate: RDF::Vocab::DC.date

my_thing      = Thing.new
my_thing.date = Date.today

puts my_thing.dump :ntriples
# _:g70072864570340 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .
# _:g70072864570340 <http://purl.org/dc/terms/date> "2014-06-19Z"^^<http://www.w3.org/2001/XMLSchema#date> .
```

Data is cast back to the appropriate class when it is accessed.

```ruby
my_thing.date
# => [Thu, 19 Jun 2014]
```

Note that you can mix types on a single property.

```ruby
my_thing.date << DateTime.now
my_thing.date << "circa 2014"
my_thing.date
# => [Thu, 19 Jun 2014, Thu, 19 Jun 2014 11:39:21 -0700, "circa 2014"]

puts my_thing.dump :ntriples
# _:g70072864570340 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .
# _:g70072864570340 <http://purl.org/dc/terms/date> "2014-06-19Z"^^<http://www.w3.org/2001/XMLSchema#date> .
# _:g70072864570340 <http://purl.org/dc/terms/date> "2014-06-19T11:39:21-07:00"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
# _:g70072864570340 <http://purl.org/dc/terms/date> "circa 2014" .
```

Repositories and Persistence
-----------------------------

Resources can persist to various databases and triplestores though integration with [RDF::Repository](http://rubydoc.info/github/ruby-rdf/rdf/RDF/Repository).

```ruby
# Registers in-memory repositories. Other implementations of
# RDF::Repository support persistence to (e.g.) triplestores & NoSQL
# databases.
ActiveTriples::Repositories.add_repository :default, RDF::Repository.new
ActiveTriples::Repositories.add_repository :people,  RDF::Repository.new

class Person
  include  ActiveTriples::RDFSource

  configure type:       RDF::Vocab::FOAF.Person,
            base_uri:   'http://example.org/people#',
            repository: :people
  property :name, predicate: RDF::Vocab::FOAF.name
end

class Thing
  include  ActiveTriples::RDFSource

  configure type:       RDF::OWL.Thing,
            base_uri:   'http://example.org/things#',
            repository: :default

  property :title,       predicate: RDF::Vocab::DC.title
  property :description, predicate: RDF::Vocab::DC.description
  property :creator,     predicate: RDF::Vocab::DC.creator, class_name: 'Person'
end

t         = Thing.new('1')
t.title   = 'A Thing'
t.creator = Person.new('1')

t.persisted? # => false

ActiveTriples::Repositories.repositories[:default].dump :ntriples
# => ""

t.creator.first.name = 'Tove'
t.persist!

puts ActiveTriples::Repositories.repositories[:default].dump :ntriples
# <http://example.org/things#1> <http://purl.org/dc/terms/title> "A Thing" .
# <http://example.org/things#1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Thing> .
# <http://example.org/things#1> <http://purl.org/dc/terms/creator> <http://example.org/people#1> .
# <http://example.org/people#1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
# <http://example.org/people#1> <http://xmlns.com/foaf/0.1/name> "Tove" .
```

Contributing
-------------

Please observe the following guidelines:

 - Do your work in a feature branch based on ```develop``` and rebase before submitting a pull request.
 - Write tests for your contributions.
 - Document every method you add using YARD annotations. (_Note: Annotations are sparse in the existing codebase, help us fix that!_)
 - Organize your commits into logical units.
 - Don't leave trailing whitespace (i.e. run ```git diff --check``` before committing).
 - Use [well formed](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) commit messages.
