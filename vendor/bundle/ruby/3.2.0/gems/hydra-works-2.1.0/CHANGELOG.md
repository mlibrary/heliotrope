# v1.0.0 2018-08-17

2018-08-17: Updates to release 1.0.0 [jrgriffiniii]

2018-08-16: Updating the Travis CI build matrix to test against Ruby releases
2.5.1 and 2.4.4 [jrgriffiniii]

2018-08-13: Resolve #344; Catch various stale Hydra references [Noah Botimer]

2018-04-28: Test reversed nested collection relationships (#333) [Adam Wead]

2018-04-04: Fix characterization of audio and video files with Fits 1.2.0 [Chris
Colvard]

2018-04-02: PR to address Issues 336 337 (#338) [Esmé Cowles]

# v0.17.0 2018-02-15

2018-02-15: Bump version to 0.17.0 [Chris Colvard]

2018-02-09: Fix #334 - Add a cleanup phase to CharacterizationService [Noah
Botimer]

2017-07-25: Change derivatives specs to use FileSet.create instead of
FileSet.new [Anna Headley]

2017-06-23: only store largest height, width for characterization, fixes #327
[Anna Headley]

2017-06-23: Replace projecthydra with samvera in links [mjgiarlo]

2017-06-23: Fix testing instructions in README, fixes #328 [Anna Headley]

2017-06-15: tweak YARD [atz]

2017-05-09: Pin rubocop-rspec [cbeer]

2017-05-09: Update travis build matrix [cbeer]

2017-03-21: Exclude eicar.txt from .gem to avoid false positives from virus
scanners [Michael Klein]

2017-03-17: Removing spec/internal as that no longer exists [Jeremy Friesen]

2017-03-16: Removing an exclusion for a non-existent file [Jeremy Friesen]

2017-03-02: Bump version to 0.16.0 [Michael J. Giarlo]

2016-11-16: AddFileToFileSet: fix @param documentation [Alex Dunn]

2017-02-28: Removing content read from file input to save memory [Carolyn Cole]

# v0.16.0 2017-03-02

2017-01-31: Allows adding URL redirects as files [Andrew Myers]

2017-01-25: Updating CONTRIBUTING.md as per Hydra v11.0.0 [Jeremy Friesen]

2017-01-24: Updating Rubocop version (and adding a TODO list) [Jeremy Friesen]

2017-01-23: Ensuring up to date system gems [Jeremy Friesen]

2017-01-18: Changing how the file is retrieved for virus checking  If the
content has a path just use that  If the file is not saved to fedora use the
content  If the file is save use the datastream [Carolyn Cole]

2017-01-11: Changing to use stream instead of content so that the content is
streamed from fedora [Carolyn Cole]

# v0.15.0 2016-11-30

2016-11-30: Bumping version to 0.15 [Esmé Cowles]

2016-07-28: Updating hydra-pcdm dependency and adding test coverage for
member_of_collections method on Works [Esmé Cowles]

# v0.14.0 2016-09-06

2016-09-06: Bump to version 0.14.0 [Adam Wead]

2016-09-02: Use services for determining mime type and filename [Adam Wead]

2016-08-30: Update rspec configuration with current best practices [Chris Beer]

# v0.13.0 2016-08-23

2016-08-23: Upping the version for release 0.13.0 [Carolyn Cole]

2016-08-22: Use plain OM::XML::Document without the datastream [Adam Wead]

2016-06-01: clarify virus detection method names - detection method returns true
if virus is detected - custom ActiveModel validation is more idiomatic [Benjamin
Armintor]

2016-05-24: Change badge URLs to reflect promotion out of labs [Michael J.
Giarlo]

2016-05-24: Updating README [Adam Wead]

# v0.12.0 2016-05-24

2016-05-24: Bump to verion 0.12.0 [Adam Wead]

2016-05-23: Only use mime-type as defined on the file in ActiveFedora [Adam
Wead]

# v0.11.0 2016-05-17

2016-05-16: Bump to version 0.11.0 [Michael J. Giarlo]

2016-05-16: Use our own VirusScanner, fixes #296 [Adam Wead]

# v0.10.0 2016-05-13

2016-05-13: Bump to version 0.10.0 [Adam Wead]

2016-05-05: Persist characterization metadata on Hydra::PCDM::File [Adam Wead]

2016-05-06: Extracting VirusCheckService from module mixin [Jeremy Friesen]

2016-05-05: Refactoring to remove exclusions for rubocop [Jeremy Friesen]

2016-05-04: Tightening dependency of hydra-pcdm [Jeremy Friesen]

# v0.9.0 2016-05-04

2016-05-04: Bump to v0.9.0 [Michael J. Giarlo]

2016-04-20: Don't require ActiveFedora::Aggregation anymore [Adam Wead]

2016-04-11: Address compatibility with Solr 6 [Hector Correa]

2016-04-11: Use the same property names (creator and language) as
CurationConcerns instead of custom properties. This is required because they
share the same predicate dc:creator and dc:language [Hector Correa]

2016-03-28: Update README with updated diagram of domain model [Michael J.
Giarlo]

2016-03-08: Read content of original_file when doing AV Scan. This makes it so
ClamAV scanfile will scan file content instead of to_s. Add spec to verify that
file contents are being read. Add eicar antivirus testing file as a fixture for
integration testing. [Colin Gross]

# v0.8.1 2016-03-25

2016-03-25: Bump to 0.8.1 [Trey Pendragon]

2016-03-25: Make sure types are associated [Trey Pendragon]

# v0.8 2016-03-25

2016-03-25: Bump version to 0.8 [Trey Pendragon]

2016-03-25: Update Hydra PCDM [Trey Pendragon]

2016-03-23: Deprecate ordered_file_sets [Justin Coyne]

2016-03-04: * Improving test coverage * Removing MimeTypes #collection? method
that duplicated FileSetBehavior#collection? [Esmé Cowles]

2016-03-23: Pin rubocop to 0.37. Fixes #281 [Justin Coyne]

2016-03-23: Update README to more clearly distinguish Hydra::Works from PCDM
Works [Michael J. Giarlo]

2016-03-14: Wrap documentation [ci skip] [Justin Coyne]

2016-03-01: FileSets and Works should barf clearly when a Collection is added as
a member [Michael J. Giarlo]

2016-03-01: Remove outdated hydra-jetty documentation [Michael J. Giarlo]

2016-02-05: Collections should not allow FileSets as members. Fixes #257
[Michael J. Giarlo]

# v0.7.1 2016-02-24

2016-02-24: Bump to 0.7.1 [Justin Coyne]

2016-02-23: When destroying a work, remove it from its parents. Fixes #260
[Justin Coyne]

2016-02-23: Use a random port to start FCrepo and Solr [Justin Coyne]

2016-02-23: Update to work with the new version of rubocop [Justin Coyne]

2016-02-05: Run solr and fedora on default test ports [Justin Coyne]

# v0.7.0 2016-02-05

2016-02-05: Preparing for 0.7.0 release [Adam Wead]

2016-02-05: Support AF 9.8.x (w/ Solr 5 and FCR 4.5) [Michael J. Giarlo]

2016-02-04: Update to hydra-pcdm 0.4.0 [Michael J. Giarlo]

2016-02-04: Update README.md [Michael J. Giarlo]

2016-02-04: Do not use deprecated SimpleCov MultiFormatter syntax [Michael J.
Giarlo]

2016-02-04: README should not recommend using `members.<<` [Michael J. Giarlo]

2016-02-04: Correct the usage examples in the README. [Michael J. Giarlo]

2016-02-03: Remove stale references to engine_cart. [Michael J. Giarlo]

2016-02-03: Dump outdated references to generic things. Confusing. [Michael J.
Giarlo]

2016-02-03: Rename characterization term. [Michael J. Giarlo]

2016-02-03: Do not declare engine_cart as a dependency, because we do not use
engine_cart. [Michael J. Giarlo]

2016-02-03: Fix Rubocop violations [Michael J. Giarlo]

2016-02-03: Fixed typo [David Chandek-Stark]

# v0.6.0 2015-12-11

2015-12-11: Bump version to 0.6.0 [Justin Coyne]

2015-12-07: Removed FileSet#file_format [Justin Coyne]

2015-12-07: Remove the interstital nodes before deleting a FileSet [Justin
Coyne]

2015-12-07: Refactor tests [Justin Coyne]

2015-12-07: Remove the tests for related_object. That code is in Hydra::PCDM
[Justin Coyne]

# v0.5.0 2015-11-30

2015-11-30: Bump version to 0.5.0 [Justin Coyne]

2015-11-30: Don't overwrite solrconfig.xml if it already exists [Justin Coyne]

2015-11-13: generic_file rename to file_set. [Colin Gross]

2015-11-13: Add homepage to gemspec [Justin Coyne]

2015-11-11: remove deprecated alias_methods and classes [Nikitas Tampakis]

2015-11-11: fix deprecation warning typo [Nikitas Tampakis]

# v0.4.0 2015-11-04

2015-11-04: Bump version to 0.4.0 [Justin Coyne]

2015-10-29: RDF::DC11 has moved to RDF::Vocab [Justin Coyne]

2015-10-28: Use the Rails logger for warnings. Fixes #198 [Justin Coyne]

2015-10-28: Remove deprecated methods [Justin Coyne]

# v0.3.0 2015-10-21

2015-10-21: Bump version to 0.3.0 [Justin Coyne]

2015-10-21: Bump dependency on hydra-pcdm to 0.3.0 [Justin Coyne]

2015-10-20: Don't override methods from PCDM [Trey Terrell]

2015-10-19: Separate orderings for works/file_sets [Trey Terrell]

2015-10-19: Add new ordering for works. [Trey Terrell]

2015-10-15: bump dependency on hydra-file_characterization to >= 0.3.3 [Justin
Coyne]

2015-10-14: Move classes into the Hydra::Works::Characterization namespace
[Justin Coyne]

2015-10-13: Add fits 0.6.2 jpg output as fixture. Add coverage for fits 0.6.2
image output. Use EBUCore.hashValue predicate for file digest.  
RDF::Vocab::PREMIS.hasMessageDigest is reserved by Fedora4. Add integration
coverage for persisting values. [Colin Gross]

2015-10-12: Mock FileSet.save for less integration testing. Add integration test
so full call chain is still hit once. Rename vars for file_set. [Colin Gross]

2015-10-12: Renaming for file_set in spec/support. Update spec vars to file_set
in ch12n spec. [Colin Gross]

2015-10-13: Use a different predicate for FITS checksum [Justin Coyne]

2015-10-13: You can't shift onto an ActiveTriples property [Justin Coyne]

2015-10-13: Remove block child objects. [Trey Terrell]

2015-10-13: Remove Filter Associations [Trey Terrell]

2015-10-07: Bump gemspec to a released version of hydra-derivatives [Justin
Coyne]

2015-10-07: Remove FullTextExtraction [Justin Coyne]

2015-10-07: Remove custom mapping of file_title and file_author. Fixes #226 This
will avoid over writing existing title and author values. Update property names
in document ch12n schema. Update ch12n spec for new property names. [Colin
Gross]

2015-10-05: Rename GenericFile to FileSet [Justin Coyne]

2015-10-05: Change work predicate from GenericWork to Work [Justin Coyne]

2015-10-05: Drop prefixes on works_collection?, works_generic_file? and
works_generic_work? [Justin Coyne]

2015-10-01: Make characterization service. Open a File when given a String
source. Use stateful ch12n service object to simplify function signatures. Add
pending to derivatives integration test for docx thumbnail. Refactor of use of
derivatives needs to be done at least for docx. [Colin Gross]

2015-09-09: Get characterization from curation concerns. Implement store
metadata values in properties. Add fits outputs as fixtures for specs. Mock add
file to generic file service in spec to avoid save. Mock ldp_source.head as
Faraday::Response.new to avoid save. Refactor file ch13n call. Update default
properties and predicates. Skip test that actually calls fits.sh in CI Add
premade modules for major media types. Check term to mapping then respond_to
term for different property names. Add media type specific term-property
mapping. Add Ch13n::Base and use Ch13n top level as umbrella. Use
ActiveTriples::Schema to apply properties. Add merge strategy to handle property
and predicate conflicts. Add specs for including modules with overlapping
predicates and properties. [Colin Gross]

2015-10-05: Update hydra-derivatives to the master branch [Justin Coyne]

2015-09-29: Use hydra-derivatives 3.0.0.alpha [Justin Coyne]

2015-09-28: full text indexing of a local file [Justin Coyne]

2015-09-28: Remove unused Thumbnail module [Justin Coyne]

# v0.2.0 2015-09-18

2015-09-18: Fix 211 - Rework association names. drop parent_ and child_ [E.
Lynette Rayle]

2015-09-04: additional jetty config and dependencies [Nikitas Tampakis]

2015-09-04: add hydra_works:jetty:config task [Nikitas Tampakis]

2015-09-03: Align rubocop with curation_concens configuration [Justin Coyne]

2015-09-03: Code coverage for the FullTextExtractionService [Justin Coyne]

2015-08-26: move full text extraction from curation concerns to works. [Jose
Blanco]

2015-08-31: Prevents Rubocop from inspecting bin directory and schema.rb in
spec/internal [Matt Zumwalt]

2015-08-25: Rubocop autocorrect should transform rspec describe messages with
"NOT" and "only" properly [Michael J. Giarlo]

2015-08-21: Update documentation to show IoDecorator [Justin Coyne]

2015-08-17: Deleted contains= from spec and lib [Nabeela Jaffer]

2015-08-19: Updated to use hydra-pcdm #176 [Justin Coyne]

2015-08-14: Use Rubocop to ensure consistently styled code. [Michael J. Giarlo]

# v0.1.0 2015-08-11

2015-08-11: Bump version to 0.1.0 [Michael J. Giarlo]

2015-08-11: Update README to remove service objects and update the API [Michael
J. Giarlo]

2015-08-10: update dependencies, remove processor [Nikitas Tampakis]

2015-08-07: Update PersistDerivative call signature. Hydra::Derivatives will not
pass opts to output_file_service. Do not version deriviatives such as thumbnails
by default. Change default value of versioning to false. [Colin Gross]

2015-08-07: Bump pcdm and af-aggregation version pins. [Colin Gross]

2015-07-15: Test coverage for Hydra::Works::GenericFile::Derivatives. [Nikitas
Tampakis]

2015-08-06: Removing deprecated services and child accessors [Esmé Cowles]

2015-08-06: Changing RDF Vocabulary namespace to projecthydra.org [Esmé Cowles]

2015-08-06: Adding test coverage for poorly-covered classes and modules [Esmé
Cowles]

2015-07-31: deprecate validations in lib/hydra/works.rb. [Jose Blanco]

2015-07-29: move tests: add, get, and remove FROM services/generic_file TO
models/generic_file_spec.rb clean up models/generic_file_spec.rb comments.
remove services/*_related_object_spec.rb - not needed any more fix tests that
check for raised errors. [Jose Blanco]

2015-07-30: Migrating virus check functionality from CurationConcerns [Esmé
Cowles]

2015-07-28: Removing solr tests [Esmé Cowles]

2015-07-28: Unskipping related_objects validation now that hydra-pcdm#153 is
resolved [Esmé Cowles]

2015-07-24: Adding test for generic_file_ids [Esmé Cowles]

2015-07-28: Moving generic_work service tests to model spec [Esmé Cowles]

2015-07-24: Removing parent/child relationship between GenericFiles -- they are
leaf nodes now [Esmé Cowles]

2015-07-15: Update AddFileToGenericFile use IO in lieu of path. Refactor file
check to responds_to? :read. If present, use metadata methods of file. Add
metadata defaults depending on available methods. [Colin Gross]

2015-07-27: Moving collection service tests to collection model spec [Esmé
Cowles]

2015-07-24: Adding coveralls/simplecov filter to exclude /spec from test
coverage calculation [Esmé Cowles]

2015-07-23: Update activefedora-aggregation version to ~> 0.3 [Colin Gross]

2015-07-21: use filters, parent/child API, indexers, deprecate services [E.
Lynette Rayle]

2015-07-21: Improving test performance [Esmé Cowles]

2015-07-21: Remove extra space [Justin Coyne]

2015-07-20: Adding a file should not check for viruses twice Also refactored to
(hopefully) simplify the code. [Justin Coyne]

2015-07-20: First optimization pass to change create to new whenever possible
[E. Lynette Rayle]

2015-07-20: ignore .ruby-* files [E. Lynette Rayle]

2015-07-15: Refactor AddFileToGenericFile to not call send [Justin Coyne]

2015-07-13: Refactor logic for readability [Justin Coyne]

2015-07-13: simplify build matrix. Ensure we use jdk 8 [Justin Coyne]

2015-07-13: Remove unnecessary self pointer [Justin Coyne]

2015-07-10: test generic_files association on subclass [Matt Zumwalt]

2015-06-25: Persist derivatives output service. [Kevin Reiss]

2015-07-07: AddFileToGenericFile validates the generic_file before attempting to
save [Matt Zumwalt]

2015-07-06: AddFile and UploadFile services accept mime_type and original_name
keyword arguments.  ref #136 [Matt Zumwalt]

2015-07-06: AddFile service relies on kargs to know whether to version (instead
of inspecting the File object) [Matt Zumwalt]

2015-06-25: makes versioning optional in AddFile service.  refs
pulibrary/curation_concerns#24 [Matt Zumwalt]

2015-06-23: Adds Versioning and improves handling of contained files  * relies
on ActiveFedora’s new directly_contains_one method for ContainedFiles  * adds
Versioning to GenericWorks  * adds ability to update versioned Files with
AddFile service  * simplifies UploadFile service and makes it run a bit faster
[Matt Zumwalt]

# v0.0.1 2015-06-05

2015-06-05: Use hydra-pcdm 0.0.1 [Adam Wead]

2015-06-04: removes functionality that has been pushed down to hydra-pcdm :
AddType and MimeType Services and File filtering methods [Matt Zumwalt]

2015-06-04: imporves behavior of contained files (thumbnail, etc.) [Matt
Zumwalt]

2015-06-03: adds AddFileToGenericFile service [Matt Zumwalt]

2015-06-01: adds activefedora-aggregations and hydra-pcdm to the gemspec [Matt
Zumwalt]

2015-06-01: Fixes bug from last merge (somehow we missed changing this file)
[Matt Zumwalt]

2015-05-28: refactors namespaces to match Code Shredding document [Matt Zumwalt]

2015-05-29: Moves a generic file from one generic work to another. Fixes #76
[Hector Correa]

2015-05-19: Remove hydra-head and hydra-collections as dependencies. Fixes #99
[Justin Coyne]

2015-05-19: Refactor upload to generic_file dir; Remove tests covered by pcdm
[E. Lynette Rayle]

2015-05-18: Add services for removing collections, generic works, generic files,
and related objects [E. Lynette Rayle]

2015-05-14: New services for adding and getting collections, generic works, and
generic files.  De-dup tests. [E. Lynette Rayle]

2015-05-15: Services for file upload and thumbnail generation [Adam Wead]

2015-05-14: Identify contained file types in a Hydra::Works::GenericFile [Adam
Wead]

2015-05-14: Use AF branch with latest AT version and patch from @terrellt [Adam
Wead]

2015-05-13: README should make clear that Gemfile needs to point at GitHub for
now [Michael J. Giarlo]

2015-05-13: add multiple types for collections, generic works, and generic files
[E. Lynette Rayle]

2015-05-05: Communicate provided functionality, intended uses, and relationship
to other gems. Fixes #53. [Michael J. Giarlo]

2015-05-12: bring hydra works inline with pcdm [E. Lynette Rayle]

2015-05-06: Expand generic work, generic file, begin collection and file [Kevin
Reiss]

2015-05-06: commit as is of what was done post LDCX [Joe Atzberger]

2015-05-07: gitignore jetty [Joe Atzberger]

2015-05-05: adds hydra Contribution Guidelines [Matt Zumwalt]

2015-05-04: Update dependencies. Ignore the spec/internal directory [Justin
Coyne]

2015-03-27: A fresh start on hydra-works [Justin Coyne]

2015-02-17: Adding and structuring the geospatial use cases for the Lafayette
College Libraries [jrgriffiniii]

2015-02-12: Update README.md [Justin Coyne]

2015-02-11: Remove copy_visibility_to_files [Justin Coyne]

2015-02-11: Rename `generic_file` association to `files` [Justin Coyne]

2015-02-11: Add pending test for destroying files when works are destroyed
[Justin Coyne]

2015-02-11: Remove to_solr [Justin Coyne]

2015-02-11: remove embargo [Justin Coyne]

2015-02-11: Remove Curatable [Justin Coyne]

2015-02-11: Removing human_readable_type since it is not part of the main model
[Carolyn Cole]

2015-02-11: Removing has_representative, since it is not a part of basic work
[Carolyn Cole]

2015-02-11: Add more association tests [Justin Coyne]

2015-02-11: Use index_collection_ids from Hydra::Collections [Justin Coyne]

2015-02-03: Support Fedora 4 [Justin Coyne]

2015-01-08: Add GenericFile [Justin Coyne]

2015-01-08: Separate Work from GenericWork Work is meant to be an Abstract class
where GenericWork is meant to have DC metadata. It is expected that GenericWork
will be used if the application has DC based metadata, otherwise the application
will create their own work class extending Hydra::Works::Work. [Justin Coyne]

2015-01-08: Update to fedora-4 [Justin Coyne]

2015-01-08: Remove dependency on sufia-models [Justin Coyne]

2014-10-28: Adding Conference Event Use Case [Jeremy Friesen]

2014-10-16: Stanford cases [Joe Atzberger]

2014-10-16: Remove placeholder in populated directory [Joe Atzberger]

2014-10-14: Adds Northwestern DisplaySet and AdminSet use case. [Thomas Scherz]

2014-10-14: Adds Northwesten Playlist Use Case [Thomas Scherz]

2014-10-14: Adds UCinn LinkedResource use case. [Thomas Scherz]

2014-10-08: Adds Princeton use cases with examples. [Jon Stroop]

2014-10-09: Clarifying Use Case Timeline [Jeremy Friesen]

2014-10-09: Removing WithLinkedResource module [Jeremy Friesen]

2014-10-09: Opening multiple sponsorships of use cases [Jeremy Friesen]

2014-10-09: Updating CONTRIBUTING.md to render < and > tags [Jeremy Friesen]

2014-10-08: Adds Penn State ScholarSphere work use case, per #9 [Michael J.
Giarlo]

2014-10-08: Adding CONTRIBUTING document [Jeremy Friesen]

2014-10-08: Update copyright year [Justin Coyne]

2014-10-08: Use Apache 2 license [Justin Coyne]

2014-10-08: Update Readme [Justin Coyne]

2014-10-08: Remove the WithEditors module, it is not a core concern. Fixes #2
[Justin Coyne]

2014-10-06: Add code from worthwhile-models [Justin Coyne]

2014-10-03: Update license and gem metadata. [Justin Coyne]

2014-10-03: Generated gem [Justin Coyne]
