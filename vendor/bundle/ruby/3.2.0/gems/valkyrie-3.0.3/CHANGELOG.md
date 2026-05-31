# v3.0.3 2023-05-15

## Changes since last release

* Avoid `delegate` in ChangeSet. ([dlpierce](https://github.com/dlpierce))

Additional thanks to the following for code review and issue reports leading to
this release:

* [ShanaLMoore](https://github.com/ShanaLMoore)
* [jeremyf](https://github.com/jeremyf)

# v3.0.2 2023-04-10

## Changes since last release

* Use `find_each` in ActiveRecord adapter: #925
    ([tpendragon](https://github.com/tpendragon))

Additional thanks to the following for code review and issue reports leading to
this release:

* [dchandekstark](https://github.com/dchandekstark)

# v3.0.1 2023-01-26

## Changes since last release

* Avoid using `awk` in shared specs: #921 ([dunn](https://github.com/dunn))

# v3.0.0 2023-01-24

## Changes since last release

* Full Ruby 3.0 support: #919 ([cjcolvar](https://github.com/cjcolvar))
* Fixed Ruby 2.7.x support: #916 ([tpendragon](https://github.com/tpendragon)), #918
  ([jrgriffiniii](https://github.com/jrgriffiniii))
* Dropped support for Ruby 2.5.x: #916 ([tpendragon](https://github.com/tpendragon))
* see previous 3.0.0 beta release notes for further changes

# v3.0.0.rc1 2022-08-09

## Unchanged from 3.0.0.beta3

# v3.0.0.beta3 2022-08-09

## Changes since last release

* Fix Ruby 3.0 support issues
  [marrus-sh](https://github.com/marrus-sh)

# v3.0.0.beta2 2022-06-15

## Changes since last release

* Update pcdm_use warning
  [dchandekstark](https://github.com/dchandekstark)
* Add support for Faraday 2
  [tpendragon](https://github.com/tpendragon)
* Rails 7 Support
  [cgalarza](https://github.com/cgalarza)
  [tpendragon](https://github.com/tpendragon)
* Support discovery of multiple disk adapters on different paths.
  [no-reply](https://github.com/tpendragon)
* New Product Owner: Alexandra Dunn!
  [dunn](https://github.com/dunn)

Additional thanks to the following for code review and issue reports leading to
this release:

[cjcolvar](https://github.com/cjcolvar)

# v3.0.0.beta1 2021-10-18

## Changes since last release

* More informative NoMethodError for missing custom queries.
  [no-reply](https://github.com/no-reply)
* Persisters error if you save something which existed at query time, but has
  since been deleted.
* Shared write-only persisters.
* Solr ModelConverter performance.
* Don't hold open a file handle from StorageAdapter#upload/find_by
* Files can be #close'd.
* Remove Draper
* Remove deprecated string equality function.
* Remove deprecated BlacklistedValue.
* Allow reform upgrade to 2.6.
* Don't require a specific error message in shared specs
  [tpendragon](https://github.com/tpendragon)

Additional thanks to the following for code review and issue reports leading to
this release:

[hackartisan](https://github.com/hackartisan)
[eliotjordan](https://github.com/eliotjordan)


# v2.2.0 2021-05-06

## Changes since last release

* Add support for Fedora 6.
  [tpendragon](https://github.com/tpendragon)
* Deprecate pcdmuse:PreservationMasterFile in favor of pcdmuse:PreservationFile
  [escowles](https://github.com/escowles)
* Improve spec docs for resource.rb
  [dchandekstark](https://github.com/dchandekstark)
* Memoize resource in Solr queries to reduce Solr calls.
  [dchandekstark](https://github.com/dchandekstark)

# v2.1.2 2021-04-19

## Changes since last release

* Tighten reform dependency
  [tpendragon](https://github.com/tpendragon)
* Loosen RDF Dependency
  [no-reply](https://github.com/no-reply)
* Update development ruby version in .tool-versions
  [hackartisan](https://github.com/hackartisan)
* Use Lando for development
  [tpendragon](https://github.com/tpendragon)
* Deprecate Blacklist in favor of Denylist.
  [jeremyf](https://github.com/jeremyf)
* Make DateTime handling in Fedora/Solr persisters consistent with others.
  [hcayless](https://github.com/hcayless)
* Add open-ended Rake support.
  [no-reply](https://github.com/no-reply)

Additional thanks to the following for code review and issue reports leading to
this release:

[cjcolvar](https://github.com/cjcolvar)
[escowles](https://github.com/escowles)
[jeremyf](https://github.com/jeremyf)

# v2.1.1 2020-03-12

## Changes since last release

* Add Ruby 2.7 support.
  [tpendragon](https://github.com/tpendragon)
* Make ID & String equality symmetrical
  [no-reply](https://github.com/no-reply)

Additional thanks to the following for code review and issue reports leading to
this release:

[cjcolvar](https://github.com/cjcolvar)
[escowles](https://github.com/escowles)
[jeremyf](https://github.com/jeremyf)

# v2.1.0 2020-01-09

## Changes since last release

* Use `::` prefixed names for `JSON::LD` references.
  [no-reply](https://github.com/no-reply)
* Use SVG instead of PNG for version badge.
  [hackartisan](https://github.com/hackartisan)
* Fix Rubocop for latest Bixby.
  [hackartisan](https://github.com/hackartisan)
* Valkyrie IDs equal string equivalent of ID to String with config
  [jlevnhv](https://github.com/jlevnhv)
* Add optional model parameter to find_inverse_references_by and
find_references_by
  [elrayle](https://github.com/elrayle)
  [laritakr](https://github.com/laritakr)
* Add parity in schema.key lookup for `ordered_attribute?`
  [jeremyf](https://github.com/jeremyf)
* Order member_ids when using schema-style attributes method.
  [no-reply](https://github.com/no-reply)
* Use DEFAULT_FEDORA_VERSION constant for Fedora adapter.
  [no-reply](https://github.com/no-reply)
* Stop testing ActiveRecord 5.1
  [scherztc](https://github.com/scherztc)
* Rename ListNode#target_uri to ListNode#target
  [mbklein](https://github.com/mbklein)
* Document that Solr Persister is intended to be used as a secondary persister.
  [hweng](https://github.com/hweng)
* Remove unused database tables from schema.rb
  [scherztc](https://github.com/scherztc)
* Alternate Identifier documentation
  [escowles](https://github.com/escowles)
* Remove suggest component in example Solr Config
  [hweng](https://github.com/hweng)
* Remove unused db/seeds.rb
  [scherztc](https://github.com/scherztc)
* Replace YARD Doc for Solr adapter with references to Memory Adapter.
  [afred](https://github.com/afred)
* Refactor shadowed variable in buffered persister spec.
  [jeremyf](https://github.com/jeremyf)
* Use example.com instead of made-up URLs
  [escowles](https://github.com/escowles)
* Add count_all_of_model query
  [christinach](https://github.com/christinach)
  [blancoj](https://github.com/blancoj)
* Raise an error when unable to find a StorageAdapter
  [bkiahstroud](https://github.com/bkiahstroud)
  [FCRodriguez7](https://github.com/FCRodriguez7)
  [kcompsci](https://github.com/kcompsci)
* Allow find_inverse_reference_by property to be either ordered or not.
  [elrayle](https://github.com/elrayle)
* Randomized spec order
  [jeremyf](https://github.com/jeremyf)
* Allow Valkyrie logging to be tagged with a context and suppressed.
  [jeremyf](https://github.com/jeremyf)
* Fix documentation for Valkyrie::Persister::Memory being disassociated.
  [jeremyf](https://github.com/jeremyf)
* Suppress Solr warnings in tests.
  [jeremyf](https://github.com/jeremyf)
* Add `Valkyrie::Types::Relation` and `Valkyrie::Types::OrderedRelation`
  [luisgreg99](https://github.com/luisgreg99)
  [lsat12357](https://github.com/lsat12357)
  [foglabs](https://github.com/foglabs)
  [dgcliff](https://github.com/dgcliff)

# v2.0.2 2019-10-17

## Changes since last release

* Fix nil not persisting with the ActiveRecord adapter.
  [tpendragon](https://github.com/tpendragon)
* Define setters when building a Resource schema with `.attributes`
  [no-reply](https://github.com/no-reply)

Additional thanks to the following for code review and issue reports leading to
this release:

[coblej](https://github.com/coblej)

# v2.0.1 2019-07-03

## Changes since last release

* Remove strftime from `Fedora::Persister::ModelConverter`
  [tpendragon](https://github.com/tpendragon)
* Only parse ISO8601 strings into DateTimes
  [awead](https://github.com/awead)


Additional thanks to the following for code review and issue reports leading to
this release:

[dgcliff](https://github.com/dgcliff)

# v2.0.0 2019-06-06

## Changes since last release

* Make LDP optional (Add `gem ldp` to Gemfile if using Fedora)
* Make ActiveRecord optional (Add `gem activerecord` to Gemfile if using
  Postgres)
* Make RSolr optional (Add `gem rsolr` to Gemfile if using Solr)
* Remove deprecated `standardize_query_result` argument.
* Remove deprecated `Valkyrie::ID#to_uri`
* Remove ActiveFedora as a dependency.
* Remove deprecated `Valkyrie::Persistence::Fedora::PermissiveSchema.alternate_ids`
* Remove deprecated `Valkyrie::Persistence::Fedora::PermissiveSchema.references`
* Upgrade `dry-types` to `1.0.x`
* Fedora Adapter default is now version 5.
* Require a symbol key when instantiating a Valkyrie::Resource (string keys are no longer valid)
* Remove deprecated `type.member()` method (use `type.of()`)
* Remove deprecated `Valkyrie::Types::Int` (use `Valkyrie::Types::Integer`)
* Performance improvements

## Changes Without Deprecations in `1.6.0`

1. Overriding an attribute getter no longer changes the output of `to_h`. If
   you've overridden something via `def title; "overwritten"; end`, then `to_h`
   will now have what was set via the setter or initializer, not `overwritten`.
2. Setting attribute values via overriding instance variables no longer works.
   Please use `#set_value` if you need dynamic setting, as this will be a stable
   API.
3. `Valkyrie::Resource#to_h` no longer includes keys with `nil` values.

## Upgrade Guide

1. Upgrade Valkyrie to `1.6.0` in your application, run tests, and fix all
   deprecations output to console.
2. Upgrade Valkyrie to `2.0.0` in your application.
3. Failing tests at this point are likely due to behavior in the "Changes
   Without Deprecations" section above. If you have any trouble, please contact
   us in the #valkyrie channel in [Samvera Slack](http://slack.samvera.org/).

## New Product Owner

All of us who have been part of the Valkyrie project so far would like to thank
[Carolyn Cole](https://github.com/carolyncole) for her role so far as Product Owner.
We'd like to welcome [Kate Lynch](https://github.com/kelynch), who will be
taking over effective immediately!

## Special Thanks

This is the first major version of Valkyrie since 1.0 over a year ago. A lot of
work has gone into it, and I'd like to take the chance to thank everyone
involved for their contributions in the last year:


[DanCoughlin](https://github.com/DanCoughlin)
[awead](https://github.com/awead)
[cam156](https://github.com/cam156)
[carolyncole](https://github.com/carolyncole)
[cjcolvar](https://github.com/cjcolvar)
[dgcliff](https://github.com/dgcliff)
[escowles](https://github.com/escowles)
[hackartisan](https://github.com/hackartisan)
[jeremyf](https://github.com/jeremyf)
[jrgriffiniii](https://github.com/jrgriffiniii)
[kelynch](https://github.com/kelynch)
[mbklein](https://github.com/mbklein)
[mjgiarlo](https://github.com/mjgiarlo)
[mtribone](https://github.com/mtribone)
[no-reply](https://github.com/no-reply)
[ojlyytinen](https://github.com/ojlyytinen)
[revgum](https://github.com/revgum)
[stkenny](https://github.com/stkenny)
[tpendragon](https://github.com/tpendragon)

# v1.7.1 2019-05-30

## Changes since last release

* Fix ROOT_PATH error in StorageAdapter#upload shared specs
  [tpendragon](https://github.com/tpendragon)

Additional thanks to the following for code review and issue reports leading to
this release:

[escowles](https://github.com/escowles)

# v1.7.0 2019-05-29

## Changes since last release

* Permit storage adapters to have arbitrary arguments to #upload.
  [jrgriffiniii](https://github.com/jrgriffiniii)
* Storage adapters can now all upload regular IO objects.
  [tpendragon](https://github.com/tpendragon)
* Fedora Storage Adapter has a configurable `resource_uri_transformer` for going
  from a `Resource` to a Fedora path.
  [elrayle](https://github.com/elrayle)
* Improve Gem metadata and allow Bundler 2
  [jcoyne](https://github.com/jcoyne)

# v1.6.0 2019-04-17

## Changes since last release

* Deprecation in preparation for LDP to be optional
* Deprecation in preparation for RSolr to be optional
* Deprecation in preparation for ActiveRecord to be optional
* Remove Rails requirement
* Remove ActiveTriples dependency.

Additional thanks to the following for code review and issue reports leading to
this release:

[carolyncole](https://github.com/carolyncole)
[dgcliff](https://github.com/dgcliff)
[escowles](https://github.com/escowles)
[no-reply](https://github.com/no-reply)

# v1.5.1 2019-02-08

## Changes since last release

* Namespace shared-spec resources to avoid conflict in apps.
  [tpendragon](https://github.com/tpendragon)

Additional thanks to the following for code review and issue reports leading to
this release:

[cjcolvar](https://github.com/cjcolvar)
[escowles](https://github.com/escowles)

# v1.5.0 2019-02-06

## Changes since last release

* Fix solr casting when an updated_at key isn't present in the solr document.
  [tpendragon](https://github.com/tpendragon)
* Add missing query service requirement to persister shared specs
  [cjcolvar](https://github.com/cjcolvar)
* Provide a warning when postgres adapter overwrites an ID, deprecate this
  behavior so it will throw an exception in the future.
  [cam156](https://github.com/cam156)
  [hackartisan](https://github.com/hackartisan)
  [tpendragon](https://github.com/tpendragon)
* Add support for passing just an ID to find_inverse_references_by
  [cam156](https://github.com/cam156)
  [hackartisan](https://github.com/hackartisan)
* Fix memory adapter raising an exception in find_by_alternate_identifier when
  there are resources without the alternate_identifier attribute.
  [jeremyf](https://github.com/jeremyf)
* Provide a warning when using the postgres adapter without manually providing
  the pg gem, so it can be an optional dependency in 2.0.0.
  [hackartisan](https://github.com/hackartisan)
* Provide guidance in specs on how to define alternate_ids
  [cjcolvar](https://github.com/cjcolvar)
* Upload files to Fedora using form/multipart.
  [tpendragon](https://github.com/tpendragon)
* Improve CompositePersister documentation.
  [tpendragon](https://github.com/tpendragon)
* Add a Valkyrie::Types::Params::ID type which handles when an HTML form passes
  an empty string value.
  [tpendragon](https://github.com/tpendragon)
* Deprecate .member on Valkyrie::Types::Array & Set
  [tpendragon](https://github.com/tpendragon)
* Fix updated_at not being set correctly for the Solr adapter, fix shared specs.
  [tpendragon](https://github.com/tpendragon)

Additional thanks to the following for code review and issue reports leading to
this release:

[awead](https://github.com/awead)
[escowles](https://github.com/escowles)
[kelynch](https://github.com/kelynch)
[mbklein](https://github.com/mbklein)
[mjgiarlo](https://github.com/mjgiarlo)
[no-reply](https://github.com/no-reply)
[revgum](https://github.com/revgum)

# v1.5.0 RC2 2019-02-01

## Changes since last release

* Fix solr casting when an updated_at key isn't present in the solr document.
  [tpendragon](https://github.com/tpendragon)

Additional thanks to the following for code review:

[mjgiarlo](https://github.com/mjgiarlo)

# v1.5.0 RC1 2019-02-01

## Changes since last release

* Add missing query service requirement to persister shared specs
  [cjcolvar](https://github.com/cjcolvar)
* Provide a warning when postgres adapter overwrites an ID, deprecate this
  behavior so it will throw an exception in the future.
  [cam156](https://github.com/cam156)
  [hackartisan](https://github.com/hackartisan)
  [tpendragon](https://github.com/tpendragon)
* Add support for passing just an ID to find_inverse_references_by
  [cam156](https://github.com/cam156)
  [hackartisan](https://github.com/hackartisan)
* Fix memory adapter raising an exception in find_by_alternate_identifier when
  there are resources without the alternate_identifier attribute.
  [jeremyf](https://github.com/jeremyf)
* Provide a warning when using the postgres adapter without manually providing
  the pg gem, so it can be an optional dependency in 2.0.0.
  [hackartisan](https://github.com/hackartisan)
* Provide guidance in specs on how to define alternate_ids
  [cjcolvar](https://github.com/cjcolvar)
* Upload files to Fedora using form/multipart.
  [tpendragon](https://github.com/tpendragon)
* Improve CompositePersister documentation.
  [tpendragon](https://github.com/tpendragon)
* Add a Valkyrie::Types::Params::ID type which handles when an HTML form passes
  an empty string value.
  [tpendragon](https://github.com/tpendragon)
* Deprecate .member on Valkyrie::Types::Array & Set
  [tpendragon](https://github.com/tpendragon)
* Fix updated_at not being set correctly for the Solr adapter, fix shared specs.
  [tpendragon](https://github.com/tpendragon)

Additional thanks to the following for code review and issue reports leading to
this release:

[awead](https://github.com/awead)
[escowles](https://github.com/escowles)
[kelynch](https://github.com/kelynch)
[mbklein](https://github.com/mbklein)
[no-reply](https://github.com/no-reply)
[revgum](https://github.com/revgum)

# v1.4.0 2019-01-08

## Changes since last release.

* Add support for Fedora 5
  [escowles](https://github.com/escowles)

# v1.3.0 2018-12-03

## Changes since last release

* Add deprecations for known methods changing in 2.0
* Add `set_value` method.

# v1.2.2 2018-10-05

## Changes since last release

* Fix consistency in adapter's responses to queries.
  [ojlyytinen](https://github.com/ojlyytinen)

# v1.2.1 2018-09-25

## Changes since last release

* Fix solr persister to pass through exceptions on timeout
  [hackartisan](https://github.com/hackartisan)
* Fix generated specs to work with shared_specs expectation
  [revgum](https://github.com/revgum)

# v1.2.0 2018-08-29

## Changes since last release

* Added `optimistic_locking_enabled?` to ChangeSets.

# v1.2.0.RC3 2018-08-15

## Changes since last release

* Fix for postgres optimistic locking.

# v1.2.0.RC2 2018-08-10

## Changes since last release

* Support for ordered properties.
  [Documentation](https://github.com/samvera-labs/valkyrie/wiki/Using-Types#ordering-values)
* Shared specs for Solr indexers.

# v1.2.0.RC1 2018-08-09

## Changes since last release

* Support for single values.
  [Documentation](https://github.com/samvera-labs/valkyrie/wiki/Using-Types#singular-values)
* Optimistic Locking.
  [Documentation](https://github.com/samvera-labs/valkyrie/wiki/Optimistic-Locking)
* Remove reliance on ActiveFedora for Fedora Storage Adapter.
* Only load adapters if referenced.
* Postgres Adapter uses transactions for `save_all`
* Resources now include `id` attribute by default.

## Special Thanks

This release was made possible by a community sprint undertaken between Penn
State University Libraries & Princeton University Library. Thanks to the
following participants who made it happen:

* [awead](https://github.com/awead)
* [cam156](https://github.com/cam156)
* [DanCoughlin](https://github.com/DanCoughlin)
* [escowles](https://github.com/escowles)
* [hackartisan](https://github.com/hackartisan)
* [jrgriffiniii](https://github.com/jrgriffiniii)
* [mtribone](https://github.com/mtribone)
* [tpendragon](https://github.com/tpendragon)

# v1.1.2 2018-06-08

## Changes since last release

* Performance improvements for ActiveRecord to Valkyrie::Resource conversions.
    [tpendragon](https://github.com/tpendragon)

# v1.1.1 2018-05-31

## Changes since last release

* Loosened ActiveRecord restriction to allow upgrading pg gem to 1.0.
    [hackartisan](https://github.com/hackartisan)

# v1.1.0 2018-05-08

## Changes since last release

* Added `find_by_alternate_identifier` query.
    [stkenny](https://github.com/stkenny)
* Added Docker environment for development.
    [mbklein](https://github.com/mbklein)
* Fixed README documentation.
    [revgum](https://github.com/revgum)
* Deprecated `Valkyrie::Persistence::Fedora::PermissiveSchema.references`
* Deprecated `Valkyrie::Persistence::Fedora::PermissiveSchema.alternate_ids`

# v1.0.0 2018-03-23

## Changes since last release

* Final release of 1.0.0!
* Support slashes in IDs for Fedora adapter.
    [dlpierce](https://github.com/dlpierce)
* Added find_many_by_ids query.
* Enforces only persisting arrays - no scalars.
* Fixes casting edge cases for `Set` and `Array`.
* Significantly improved documentation
* Support `Booleans`
* Support `RDF::Literal`
* Fix support for `DateTime`.
* Fix rake tasks leaking out of gem.
* Extract derivatives/file characterization to
    [valkyrie-derivatives](https://github.com/samvera-labs/valkyrie-derivatives)
* ChangeSet shared spec
* Allow strings as an argument for find_by.
* Improve development documentation.
* Throw error on `find_inverse_references_by` for unsaved `resource`.

# v1.0.0.RC2 2018-03-14

## Changes since last release

* Support slashes in IDs for Fedora adapter.
    [dlpierce](https://github.com/dlpierce)

# v1.0.0.RC1 2018-03-02

Initial Release

## Changes Since Last Sprint

* Added find_many_by_ids query.
* Enforces only persisting arrays - no scalars.
* Fixes casting edge cases for `Set` and `Array`.
* Significantly improved documentation
* Support `Booleans`
* Support `RDF::Literal`
* Fix support for `DateTime`.
* Fix rake tasks leaking out of gem.
* Extract derivatives/file characterization to
    [valkyrie-derivatives](https://github.com/samvera-labs/valkyrie-derivatives)
* ChangeSet shared spec
* Allow strings as an argument for find_by.
* Improve development documentation.
* Throw error on `find_inverse_references_by` for unsaved `resource`.

## Special Thanks to All Contributors:

* [atz](https://github.com/atz)
* [awead](https://github.com/awead)
* [barmintor](https://github.com/barmintor)
* [bmquinn](https://github.com/bmquinn)
* [cam156](https://github.com/cam156)
* [carrickr](https://github.com/carrickr)
* [cbeer](https://github.com/cbeer)
* [cjcolvar](https://github.com/cjcolvar)
* [csyversen](https://github.com/csyversen)
* [dlpierce](https://github.com/dlpierce)
* [escowles](https://github.com/escowles)
* [geekscruff](https://github.com/geekscruff)
* [hackartisan](https://github.com/hackartisan)
* [jcoyne](https://github.com/jcoyne)
* [jeremyf](https://github.com/jeremyf)
* [jgondron](https://github.com/jgondron)
* [jrgriffiniii](https://github.com/jrgriffiniii)
* [mbklein](https://github.com/mbklein)
* [stkenny](https://github.com/stkenny)
* [tpendragon](https://github.com/tpendragon)
