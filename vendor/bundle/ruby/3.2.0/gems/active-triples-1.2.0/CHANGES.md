1.2.0
----
  - Add support for Ruby 3.0, 3.1 and 3.2.
  - Implemented `RDFSource#term?` for compatibility with current
  `RDF::Enumerable` behavior.

1.1.1
----
  - Major performance improvements due to a minor change in how
    properties are resolved.

1.1.0
----
  - Add support for RDF.rb 3.0

1.0.0
----
  - Finalize 1.0.0 APIs

0.11.0
----
  - Reworks ParentStrategy to use an Transaction over a well defined
  "extended bounded description".
  - Converts Relation to an Enumerable for more efficient access to
  property values.
  - Cleans up .Relation equality and added `#|` & `#&` for Set style
  comparison.
  - Deprecates `Relation#first_or_create`.
  - Removes dependency on the `linkeddata` gem. Users should require
  individual RDF libraries as needed.
  - Adds inheritance of configured types when subclassing an
  `RDFSource`.
  - Uses `URI#intern` to avoid repeated allocations of common URIs.
  - Changes handling of language and datatyped Literals in
  `Relation#each` & `#to_a`;
    - now returns `RDF::Literal` for lanugage tagged strings and
    for unknown datatypes.

0.10.0
----
  - Fix Identifiable for ActiveFedora [Trey Pendragon]
  - Upgrade to RDF.rb 2.0.2 [Tom Johnson]
  - Avoid touching each_statement on initialization [Tom Johnson]
  - Drop support for Ruby 2.0

0.9.0
-----
 - Upgrade to RDF.rb 2.0

0.8.3
-----
 - Do not include all predicates from other subjects in unregistered_predicates
 - Minor corrections to README.md

0.8.2
-----
* Allow PersistenceStrategy set by property config [Tom Johnson]
* Extend NodeConfig for arbitrary properties [Tom Johnson]
* Add `Relation#delete?` and `#swap` [Tom Johnson]
* Make Relation#delete singular; add #subtract [Tom Johnson]
* Re-add `Relation#delete` with a new implementation [Tom Johnson]
* Documentation and formatting cleanup on Relation [Tom Johnson]
* Remove Relation#reset! [Tom Johnson]
* Remove `Relation#[]=` [Tom Johnson]
* Remove Relation#delete [Tom Johnson]
* FIX #200 Use == instead of eql? for resource equality test [E. Lynette Rayle]
* Add some docs and tests for `PropertyBuilder` [Tom Johnson]
* Test undefined property on Relation#set [Tom Johnson]
* add loaded flag to lazy load property sources with parent_strategy [E. Lynette Rayle]
* Add deprecation warning [MJ Suhonos]
* Rename #obj to #source for clarity [MJ Suhonos]
* Update Guardfile [MJ Suhonos]
* Update comment terminology [MJ Suhonos]
* Remove reference to concrete persistable from abstract class [MJ Suhonos]
* Allow fetch to pass args to RDF::Reader.open [Justin Coyne]
* Delegate join to Relation. [Trey Terrell]
* Change ParentStrategy usage [Tom Johnson]
* Delegate #size in Relation. [Trey Terrell]
* Remove singleton_class call from RepositoryStrategy [Tom Johnson]
* Convert ancestors enumerator method to Class [Tom Johnson]
* Avoid circularity in `ParentStrategy` [Tom Johnson]
* Update .travis.yml Rubies to match RDF.rb [Tom Johnson]
* Add frozen_string_literals pragma [Justin Coyne]
* Fixup specs [Tom Johnson]
* Specs/docs for ValueError scenarios on #set_value [Tom Johnson]
* Add initial docs/specs for `RDFSource#attributes` [Tom Johnson]
* Add docs and specs for `Relation#first_or_create` [Tom Johnson]
* Add tests & docs for `Relation#build` [Tom Johnson]
* Make `Relation#clear` atomic [Tom Johnson]
* Test `RDFSource#rdf_label` [Tom Johnson]
* Fix for circular parent relationships [Tom Johnson]
* Add documentation and tests for key Relation [Tom Johnson]
* Refactor Relation#value_arguments [Tom Johnson]
* Move property methods from RDFSource in Properties [Tom Johnson]
* Add documentation and some tests for Properties [Tom Johnson]
* Refactor and rearrange RDFSource & Reflection [Tom Johnson]
* Finish documentation and testing of Reflection [Tom Johnson]
* Cleaner handling of undefined properties [Tom Johnson]
* Add some tests for `#get_values` [Tom Johnson]
* Make `#set_value` return the Relation it updates [Tom Johnson]
* Add triple in `#set_value` when argument is self [Tom Johnson]
* Removes odd logic surrounding property clearance [Tom Johnson]
* Removing OpenStruct in favor of PORO [Jeremy Friesen]
* Switching from Array() to Array.wrap [Jeremy Friesen]
* Fixup RDF.rb and rdf-spec dependencies [Tom Johnson]
* Track latest `rdf-spec` and `rdf-vocab` [Tom Johnson]
* Complete update to use RDF::Vocab [Tom Johnson]
* Use rdf-vocab for vocabularies [Justin Coyne]
* Add `RDFSource#graph_name` since quads aren't returned [Tom Johnson]
* Update specs to use a managable invalid statement [Tom Johnson]
* Test with develop version of rdf-spec [Justin Coyne]
* Graph#query is faster than using Queryable#query [Justin Coyne]
* Update error handling specs. [Tom Johnson]
* Adds a default block to `RDFSource#fetch` [Tom Johnson]
* Run `ActiveModel` lints on `RDFSource` [Tom Johnson]
* Fix ActiveModel linter to test `#to_key` [Tom Johnson]
* Remove unnecessary lines in `parent_strategy_spec` [Tom Johnson]
* Make `Relation#predicate` a public method [Tom Johnson]
* Cleanup and unit tests for `RDFSource#get_value` [Tom Johnson]
* Test ActiveModel validations with RDF's `#valid?` [Tom Johnson]
* Children should not be persisted? unless their parents are. Fixes #148 [Justin Coyne]


0.8.1
-----

  - Reverts changing `Relation`'s delete methods to remove all values until we
  have a clear path forward for those depending on that functionality.

0.8.0
-----
  - Adds RDF.rb interfaces to `RDFSource`, improving interoperability
  with other `ruby-rdf` packages.
  - Introduces a defined `Persistable` interface and
  `PersistenceStrategies`.
  - Changes `Relation`'s delete methods to remove all values, instead of
  trying to maintain a predicate -> class pair on the property
  definitions in some cases. The previous functionality was unclear and
  unreliable.
  - Adds a `Schema` concept, for defining property definitions that are
   portable across `RDFSource` types.


0.7.0
-----

__ATTN: This release withdraws support for Ruby 1.9__

  - Removes `#solrize` which was a badly named holdever from the
  ActiveFedroa days.
  - Fixes a bug on properties defined without a predicate. They are now
  rejected.
  - Disallows setting properties on the `ActiveTriples::Resource` base
  class directly. This kind of property setting is unintended and
  resulted in unexpected behavior.
  - Introduces `ActiveTriples::RDFSource` as a mixin module for which
  forms the basis of `Resource`.
    - Use of this module is now preferred to single inheritance of the
  `Resource` base class.
    - `Resource` will remain indefinitely as the generic model.
  - Renamed `Term` to `Relation`. `Term` is deprecated for removal in
  the next minor release.
  - Allow configuration of multiple `rdf:type`s.
