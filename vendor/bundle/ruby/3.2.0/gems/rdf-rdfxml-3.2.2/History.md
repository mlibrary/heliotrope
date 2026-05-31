### 0.3.9
* Allow discovery with format :rdf in addition to :rdfxml

### 0.3.8
* If rdf:RDF is found in a deeper element, look to ancestors for xml:base and xml:lang.
### 0.3.7
* Added :stylesheet option to RDF::RDFXML::Writer to allow writing of an XSL stylesheet processing instruction.
### 0.3.6
* Attempt at JRuby and REXML support; not quite there yet.
* Element content uses `#inner_text`, rather than `#inner_html`; this performs entity decoding.
* Use rdf-xsd gem instead of internal support for XMLLiterals.

### 0.3.5
* RDF.rb 0.3.4 compatibility.
* Added format detection.

### 0.3.4
* Decode XML Entity declarations when parsing.

### 0.3.3.1
* JRuby/FFI compatibility updates.
* Simplify property value ordering in writer; this was causing unnecessary prefixes to be generated.

### 0.3.3
* Change licensing to UNLICENSE.
* Only generate prefix definitions for prefixes actually used within a serialization.
* Make sure that only valid QNames are generated in writer.

### 0.3.2.1
* Fix collection serialization bug
* Assert :xml as a format type (by creating RDF::RDFXML::XML as a sub-class of Format that uses RDFXML::Reader/Writer)

### 0.3.2
* Refactor rdfcore tests using Spira and open-uri-cached.
* Improve detection and reporting of attempts to write illegal values.

### 0.3.1
* In writer
  * fix bug where a serialized subject is output again, when it appears in a collection.
  * Fix subject ordering.

### 0.3.0
* RDF.rb 0.3.0 compatibility updates
  * Remove literal_normalization and qname_hacks, add back uri_hacks (until 0.3.0)
  * Use nil for default namespace
* In Writer
  * Use only :prefixes for creating QNames.
  * Add :standard_prefixes and :default_namespace options.
  * Improve Writer#to_qname.
  * Don't try to translate rdf:_1 to rdf:li due to complex corner cases.
  * Fix problems with XMLLiteral, rdf:type and rdf:nodeID serialization.
* In Reader
  * URI canonicalization and validation.
  * Added :canonicalize, and :intern options.
  * Change :strict option to :validate.
  * Don't create unnecessary namespaces.
  * Don't use regexp to substitute base URI in URI serialization.
  * Collect prefixes when extracting mappings.
* Literal::XML
  * Add all in-scope namespaces, not just those that seem to be used.
* RSpec 2 compatibility

### 0.2.3
* Fixed QName generation in Writer based on RDF/XML Processing recommendations

### 0.2.2.1
* Ruby 1.9.2 support.
* Added script/tc to run test cases
* Mark failing XMLLiteral tests as pending

### 0.2.2
* Fix bug creating datatyped literal where datatype is a string, not an RDF::URI
* Added more XMLLiteral tests (fail, until full canonicalization working)
* Added RDF_Reader and RDF_Writer behavior expectations
* Use RDF::Writer#prefix and #prefixes implementation instead of internal version.
* Added RDF::Reader#rewind and #close, which override default behavior as stream is closed on initialization and rewinding isn't required.
* In console, load RDF.rb from parent directory, if it exists.
* Dependencies on RDF 0.2.2
* Replace String#rdf_escape with RDF::NTriples.escape
* Fixed bug in Writer where a qname was expected for sorting, but property has no qname
* Handle XMLLiteral when value is a Nokogiri node set.
* Ensure URIs are properly RDF Escaped (patch to RDF::NTriples::Writer#format_uri)

### 0.2.1
* Update for RDF 0.2.1
* Writer bug fixes:
  * RDF::Node#identifier => RDF::Node#id
  * Vocabulary.new(uri) => Vocabulary(uri)

### 0.2.0
* Updates for RDF 0.2.0
  * Use URI#intern instead of URI#new
  * Change use of Graph#predicates and Graph#objects to use as enumerables

### 0.0.3
* Added patches for the following:
  * RDF::Graph#properties
  * RDF::Graph#seq (Output rdf:Seq elements in order)
  * RDF::Graph#type_of
  * RDF::Literal.xmlliteral (Create literal and normalize XML)
  * RDF::Literal#xmlliteral?
  * RDF::Literal#anonymous? (missing from library)
  * RDF::Literal#to_s (only one of @lang or ^^type, not both)
  * RDF::URI#join (Don't add trailing '/')
* Reader fixes
* Writer complete
* Spec status
  * Isomorphic XMLLiteral tests fail due to attribute order variation
  * Reader parsing multi-line quite in NTriples test file fails due to lack of support in RDF::NTriples
  * A couple of URI normalizations fail:
    * should create <http://foo/> from <http://foo#> and ''
    * should create <http://foo/bar> from <http://foo/bar#> and ''
  * Writer test needs Turtle reader

### 0.0.2
* Added specs from RdfContext
* Added array_hacks, nokogiri_hacks, and rdf_escape
* Fixed most bugs that are not related to the underlying framework.
  * Specific failing testcases for rdf-isomorphic, RDF::Literaland others need to be constructed and added as issues against those gems.
* Removed interal graph in Reader and implement each_triple & each_statement to perform parsing

### 0.0.1
* First port from RdfContext version 0.5.4
