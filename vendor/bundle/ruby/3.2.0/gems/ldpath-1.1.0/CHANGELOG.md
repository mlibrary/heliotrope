### 1.1.0 (2020-01-21)

* replace linkeddata dependency with rdf and nokogiri
* update dependency on bundler to ~> 2.0

### 1.0.1 (2019-04-23)

* remove version restriction for linkeddata dependency

### 1.0.0 (2019-03-29)

* add ability to restrict results to passed in context
* Add Coveralls for test coverage analysis
* update to make all tests pass
* move to samvera-labs
* Refactor recursive path selector
* Extract Result#evaluate to FieldMapping#evaluate
* Defer mapping enumerables to arrays until Result#to_hash
* Remove hound's rubocop styling and replace with default upstream styles
* Convert selectors to yield enumerators instead of arrays
* Extract Ldpath::Result from Ldpath::Program
* Update travis build matrix
* Update to rdf 2.x
* Refactor grouping rule into a macro
* Refactor and/or tests to use left and right operands
* Refactor transforms to remove case statements within rules
* Add the range \u10000 - \uEFFFF to the allowed prefix chars
* Add simplecov
* Add NegatedPropertySelector from sparql property paths
* Add reasonable error handling to the ldpath binary

### 0.3.1 (2015-05-04)

* Add reasonable error handling to parsing the user input

### 0.3.0 (2015-05-04)

* push literal parsing down to literal
* map strings to strings
* Parse literals into properly typed and lang-tagged literals

### 0.2.0 (2015-05-03)

* Use rubocop to enforce a common style
* refactor parser rules
* Improve transform specs
* Add 'zero or one' path operator
* refactor recursive_path_selector
* refactoring parsing for compound selectors
* Add support for single line, sparql-style comments
* Use sparql's definition of the prefix identifier
* Adopt turtle's EBNF names for basic types
* require that the prologue occur before the mappings
* add parsing spec
* Use parse, not parse_with_debug
* Simplify the ldpath parser
* Add list-aware functions

### 0.1.0 (2015-04-04)

* Add bin/ldpath
* Update gem homepage
* Support parsing the field type options
* Parse and ignore @boost
* Support @filter
* Add more lenient whitespace parsing
* Add fn:xpath
* Complete test functions (fn:eq, fn:ne, etc)

### 0.0.2 (2015-04-02)

* Fix and test ldpath functions receiving selectors
* Load rdf/reasoner as a dev dependency
* Always attempt retrieve resources unless they've been previously fetched
* Add loose property selector (~) for allowing super-properties to be u…
* Add debug logging when loading resources
* Add tap selector for saving additional metadata while evaluating a ma… 
* Use RDF::Util::Cache by default to cache retrieved graphs
* Add fn:predicates function for retrieving available predicates for an…

### 0.0.1 (2014-07-21)

* Update README.md
* Add is and is-a tests
* Add add/or/not tests
* Add type test
* Handle mapping fields to literals
* Allow strlits to include escaped quotes
* treat functions as a mixin to the program
* Update functions to support property arrays for certain arguments
* Naive stub implementations for functions
* Improve the parser tests
* Naively try to load up RDF graphs whenver they are referenced by URI
* Add field datatype declarations
* Extract Ldpath::Selector to handle the default wrapping/unwrapping
* Add convenient accessor to parse and evaluate a program
* Reorganize Ldpath::Transform
* Re-organize the Ldpath::Parser rules
* Anywhere there's whitespace is (probably) a valid place for a multili…
* Implement partial testing selectors
* Add recursive path selector
* Implement low-hanging selectors
* add README
* Implement path selector evaluation
* Demonstrate evaluating an LDPath program with a simple property selector
* first pass at transforming the parslet output into an AST
* initial commit
