# SimpleSolrClient

A simple client and accompanying shell to help test and give simple
commands to a solr instance.


# Features:

  * Get basic info about cores (size, number of docs, etc.)
  * Basic (*very basic) add/delete/query
  * Commit/optimize/clear (empty) an index
  * Reload a core (presumably after editing a `schema.xml` or `solrconfig.xml`)
  * Inspect lists of fields, dynamicFields, copyFields, and
    fieldTypes
  * Get list of the tokens that would be created if you
    send a string to a paricular fieldType (like in the
    solr admin analysis page)
  * Determine (usually) which fields (and their properties) would be
    created when a given field name is indexed, taking into
    account dynamicField and copyField directives.


Additional features when running against a localhost solr:
  * Spin up a temporary core to play with
  * Add/remove fields, dynamic_fields, copy_fields, and field types
    on the fly and save them back, ready for a reload
  * Create temporary cores for doing testing



## Basic add and delete of documents, and simple queries

Right now, it supports only the most basic add/delete/query operations.
Adding in support for more complex queries is on the TODO list, but took
a back seat to dealing with the schema.


```ruby

# A "client" points to a running solr, independent of the particular core
# You get a core from it.

client = SimpleSolrClient::Client.new('http://localhost:8983/solr')
core = client.core('core1') # must already exist!
core.url #=> "http://localhost:8983/solr/core1"

core.name #=> 'core1'
core.number_of_documents #=> 7, what was in there already
core.instance_dir #=> "/Users/dueberb/devel/java/solr/example/solr/collection1/"
core.schema_file #=> <path>/<to>/<schema.xml>

# Remove all the indexed documents and (automatically) commit
core.clear

core.number_of_documents #=> 0. Automatic commit for #clear

# Add documents
#
# name_t is a text_general, multiValued, indexed, stored field
h1 = {:id => '1', :name_t=>"Bill Dueber"}
h2 = {:id => '2', :name_t=>"Danit Brown"}
h3 = {:id => '3', :name_t=>"Ziv Brown Dueber"}

core.add_docs(h1)

core.number_of_documents #=> 0? But why? Oh, right...
core.commit
core.number_of_documents #=> 1  There we go

# You can chain many core operations
core.clear.add_docs([h1,h2, h3]).commit.optimize.number_of_documents #=> 3

# only the most basic querying is currently supported
# Result of a query is a QueryResponse, which contains a list of Document
# objects, which respond to ['fieldname']

# All bring back all documents up to the page limit
core.all.size #=> 3
core.all.map{|d| d['name_t']} #=> [['Bill Dueber'], ['Danit Brown'], ['Ziv Brown Dueber']]

# Simple field/value search
docs = core.fv_search(:name_t, 'Brown')
docs.class #=>  SimpleSolrClient::Response::QueryResponse

docs.size #=> 2
docs.map{|d| d['name_t']} #=> [['Danit Brown'], ['Ziv Brown Dueber']]

# Special-case id/score as regular methods
docs.first.id #=> '2'
docs.first.score #=> 0.625

# Figure out where documents fall. "Ziv Brown Dueber" contains both
# search terms, so should come first
docs = core.fv_search(:name_t, 'Brown Dueber')
docs.size #=> 3

docs.rank('3') #=> 1 (check by id)
docs.rank('3') < docs.rank('b') #=> true

# Of course, we can do it by score
docs.score('z') > docs.score('d')

# In addition to #clear, we can delete by simple query
core.delete('name_t:Dueber').commit.number_of_documents #=> 1


```

## Field Types and analysis

Field Types are created by getting data from the API and also
parsing XML out of the schema.xml (for later creating a new
schema.xml if you'd like).

You can also ask a field type how it would tokenize an input
string via indexing or querying.

NOTE: FieldTypes _should_ be able to, say, report their XML serialization even
when outside of a particular schema object, but right now that doesn't
work. If you make changes to a field type, the only way to see the new
serialization is to call `schema.to_xml` on whichever schema you added
it to via `schema.add_field_type(ft)`



```ruby

core.schema.field_types.size #=> 23
ft = schema.field_type('text') #=> SimpleSolrClient::Schema::FieldType
ft.name #=> 'text'
ft.solr_class #=> 'solr.TextField'
ft.multi #=> true
ft.stored #=> true
ft.indexed #=> true
# etc.

newft = SimpleSolrClient::Schema::FieldType.new_from_xml(xmlstring)
schema.add_field_type(newft)

ft.name #=> text
ft.query_tokens "Don't forget me when I'm getting H20"
  #=> ["don't", "forget", "me", "when", "i'm", ["getting", "get"], "h20"]

ft.index_tokens 'When it rains, it pours'
  #=> ["when", "it", ["rains", "rain"], "it", ["pours", "pour"]]


# Check for validity

int_type = core.schema.field_type('int')
int_type.index_tokens("33") => ["33"]
int_type.index_token_valid?("33") #=> true

int_type.index_token_valid?("33.3") #=> false
int_type.index_tokens('33.3') #=>   RuntimeError
 

```



## Saving/reloading a changed configuration

Whether you change a solr install via editing a text file or
by using `schema.write`, you can always reload a core.

```ruby
core.reload
```

If you're working on localhost, you can make programmatic changes
to the schema and then ask for a write/reload cycle. It uses the API
to find the path to the schema.xml file and overwrites it.

```ruby

schema = core.schema
core.add_field Field.new(:name=>'price', :type_name=>'float')
schema.write
schema = core.reload.schema
```



## The `schema` object

Each core exposes a `schema` object that allows you to find out about
the fields, copyfields, and field types, and how they interact with 
query and index calls (like the analysis screen in the admin interface)

```ruby

# Get a list of cores
client.cores #=> ['core1', 'core2']
core = client.core('core1')

# Get an object representing the schema.xml file
schema = core.schema #=> SimpleSolrClient::Schema object

# Get lists of field, dynamicFields, and copyFields
# all as SimpleSolrClient::Schema::XXX objects

explicit_fields = schema.fields
dynamic_fields  = schema.dynamic_fields
copy_fields     = schema.copy_fields

# Get a list of FieldType object
field_types     = schema.field_types
field_type_names = schema.field_types.map(&:name) 

# Check out a specific field type and how it parses stuff 
mytexttype = schema.field_type('mytexttype') 
mytexttype.index_tokens('bill dueber solr-stuff') #=> ['bill', 'dueber', 'solr', 'stuff']
mytexttype.query_tokens('bill dueber solr-stuff') #=> ['bill', 'dueber', 'solr', 'stuff']

```

### Regular (non-dynamic) fields

Internally I call these "explicit_fields" as opposed to dynamic fields.

```
f = schema.field('id')
f.name #=> 'id'
f.type.name #=> 'string'
f.type.solr_class #=> 'solr.StrField'

# Basic attributes
# These will fall back on the fieldType if not defined for a
# particular field.

f.stored  #=> true
f.indexed #=> true
f.multi   #=> nil # defined on neither field 'id' or fieldType 'string'

# We implement a matcher, which is just string equality
f.matches('id') #=> true
f.matches('id_t') #=>false

# You can add fields, and save it back if you're on
# localhost

schema.add_field Field.new(:name=>'format', :type_name=>'string', :multi=>true, :stored=>false, :indexed=>true)

schema.write; core.reload # only on localhost

core.schema.field('format').type.name #=> 'string'

```

### Dynamic fields

The rule Solr uses for dynamic fields is "longest one wins"
Right now, I'm only handling _leading_ asterisks, so `*_t` will
work, but `text_*` will not.

```
schema.dynamic_fields.size #=> 23
f = schema.dynamic_field('*_t') #=> SimpleSolrClient::Schema::DynamicField
f.name #=> '*_t')
f.type.name #=> 'text_general'
f.stored #=> true
f.matches('name_t') #=> true
f.matches('name_t_i') #=> false
f.matches('name') #=> false

# Dynamic Fields can also be added
schema.add_dynamic_field(:name=>"*_f", :type_name=>'float')

```

### Copy Fields

CopyFields are a different beast: they only have a source and a dest, and
they can have multiple targets. For that reason, the interface is slightly
different (`#copy_fields_for` instead of just `#copy_field`)

```

# <copyField source="*_t_s", dest="*_t"/>
# <copyField source="*_t_s", dest="*_s"/>

cfs = schema.copy_fields_for('*_ts')
cfs.size #=> 2
cfs.map(&:dest) #=> ["*_t", "*_s"]

cf = SimpleSolrClient::Schema::CopyField.new('title', 'allfields')
cf.source #=> 'title'
cf.dest  #=>  'allfields'

schema.add_copy_field(cf)
```


## What will I get if I index a field named `str`?

Dynamic- and copy-fields are very convenient, but it can make it hard to
figure out what you're actually going to get in your indexed and
stored fields. I started thinking about this [at the end of this blog post](http://robotlibrarian.billdueber.com/2014/10/schemaless-solr-with-dynamicfield-and-copyfield/)

`schema.resulting_fields(str)` will take the field name given and
figure out what fields would be generated, returning an array of field
objects (which are created wholesale if need be due to dynamicFields or
copyFields).

```ruby
rs = schema.resulting_fields('name_t_s')
rs.size #=> 3

rs.map{|f| [f.name, f.type.name]}
  #=> [["name_t_s", "ignored"], ["name_t", "text"], ["name", "string"]]

rs.find_all{|f| f.stored}.map(&:name) #=> ["name"]
rs.find_all{|f| f.indexed}.map(&:name) #=> ['name_t']



```


## Installation

    $ gem install simple_solr


## Contributing

1. Fork it ( https://github.com/billdueber/simple_solr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
