# Changelog

## [1.0.3](https://github.com/samvera/ldp/tree/1.0.3) (2021-05-14)

[Full Changelog](https://github.com/samvera/ldp/compare/v1.0.1...1.0.3)

Walks back a small portion of the optimizations in 1.0.2 to support a frequently
used extend-and-override pattern.

**Merged pull requests:**

- yield to ActiveFedora's intrusive overrides [#122](https://github.com/samvera/ldp/pull/122)

## [1.0.2](https://github.com/samvera/ldp/tree/1.0.2) (2021-05-14)

[Full Changelog](https://github.com/samvera/ldp/compare/v1.0.1...1.0.2)

This release includes major performance improvements and memory optimizations.

These optimizations replace linear complexity data access operations with
constant-time equivalents. They also prevent repeated wholesale copying of
(potentially large) RDF graphs in-memory when deserializing LDP responses.

This should result in broad performance improvements in all cases. The biggest
impact will be on RDF Sources with many `ldp:contains` relationships.

**Merged pull requests:**

- don't loop over statements manually; use the library [#118](https://github.com/samvera/ldp/pull/118)
- optimize subject filtering [#119](https://github.com/samvera/ldp/pull/119)
- Adding CONTRIBUTING.md This was uploaded via automation. [#116](https://github.com/samvera/ldp/pull/116)
- fix a regression in handling for custom graph classes in `RDFSource` [#120](https://github.com/samvera/ldp/pull/120)

## [1.0.1](https://github.com/samvera/ldp/tree/1.0.1) (2020-06-12)

[Full Changelog](https://github.com/samvera/ldp/compare/v1.0.1-beta1...1.0.1)

**Closed issues:**

- Add support for Ruby 2.7.z releases [\#111](https://github.com/samvera/ldp/issues/111)
- Test against Rails release 5.1.7 and Ruby releases 2.6.3, 2.5.5, and 2.4.6 [\#108](https://github.com/samvera/ldp/issues/108)
- Add contact/mailing list info [\#97](https://github.com/samvera/ldp/issues/97)
- Update contribution guidelines for Samvera changes [\#96](https://github.com/samvera/ldp/issues/96)
- Review/remove comment about Fedora Commons 4 alpha [\#95](https://github.com/samvera/ldp/issues/95)
- Remove Gemnasium from README [\#94](https://github.com/samvera/ldp/issues/94)
- Confirm copyright statement/years [\#93](https://github.com/samvera/ldp/issues/93)
- Test using Ruby releases 2.5.1 and 2.4.4 [\#92](https://github.com/samvera/ldp/issues/92)
- Request for LDP Point Release [\#73](https://github.com/samvera/ldp/issues/73)

**Merged pull requests:**

- Adding Bixby/Rubocop and configuring upstream style checks [\#114](https://github.com/samvera/ldp/pull/114) ([randalldfloyd](https://github.com/randalldfloyd))
- Adding Ruby 2.7.z and Rails 6.y.z releases to the CircleCI build configuration [\#113](https://github.com/samvera/ldp/pull/113) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Update CircleCI Ruby and Rails versions [\#110](https://github.com/samvera/ldp/pull/110) ([botimer](https://github.com/botimer))
- Updates the CircleCI configuration to test against Rails release 5.1.7 and Ruby releases 2.6.3, 2.5.5, and 2.4.6 [\#109](https://github.com/samvera/ldp/pull/109) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Use released circleci orb. [\#107](https://github.com/samvera/ldp/pull/107) ([tpendragon](https://github.com/tpendragon))
- Switch to CircleCI [\#106](https://github.com/samvera/ldp/pull/106) ([tpendragon](https://github.com/tpendragon))
- Updating the product owner to randalldfloyd [\#105](https://github.com/samvera/ldp/pull/105) ([jrgriffiniii](https://github.com/jrgriffiniii))
- update LICENSE.txt to conform to Samvera recommendation [\#103](https://github.com/samvera/ldp/pull/103) ([barmintor](https://github.com/barmintor))
- Resolve \#96; Update docs to use templates [\#102](https://github.com/samvera/ldp/pull/102) ([botimer](https://github.com/botimer))
- Upgrades the Travis CI build matrix to use later Ruby/JRuby releases [\#101](https://github.com/samvera/ldp/pull/101) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Clean up README problems [\#100](https://github.com/samvera/ldp/pull/100) ([botimer](https://github.com/botimer))
- show uri when Ldp::Conflict is incountered [\#98](https://github.com/samvera/ldp/pull/98) ([elrayle](https://github.com/elrayle))

## [v1.0.1-beta1](https://github.com/samvera/ldp/tree/v1.0.1-beta1) (2018-03-14)

[Full Changelog](https://github.com/samvera/ldp/compare/v1.0.0...v1.0.1-beta1)

**Merged pull requests:**

- Conditional in BinarySource should check for LDP::Response [\#85](https://github.com/samvera/ldp/pull/85) ([jcoyne](https://github.com/jcoyne))

## [v1.0.0](https://github.com/samvera/ldp/tree/v1.0.0) (2018-03-14)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.7.2...v1.0.0)

## [v0.7.2](https://github.com/samvera/ldp/tree/v0.7.2) (2018-03-14)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.7.1...v0.7.2)

**Merged pull requests:**

- Fix parsing of empty content-disposition filename subfield [\#90](https://github.com/samvera/ldp/pull/90) ([mbklein](https://github.com/mbklein))

## [v0.7.1](https://github.com/samvera/ldp/tree/v0.7.1) (2018-03-13)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.7.0...v0.7.1)

**Merged pull requests:**

- Support different forms of the Content-Disposition header [\#89](https://github.com/samvera/ldp/pull/89) ([mbklein](https://github.com/mbklein))
- Update README.md for Samvera [\#87](https://github.com/samvera/ldp/pull/87) ([no-reply](https://github.com/no-reply))
- Update the build matrix [\#86](https://github.com/samvera/ldp/pull/86) ([no-reply](https://github.com/no-reply))

## [v0.7.0](https://github.com/samvera/ldp/tree/v0.7.0) (2017-06-12)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.6.4...v0.7.0)

**Merged pull requests:**

- Response.for requires the third argument. [\#82](https://github.com/samvera/ldp/pull/82) ([jcoyne](https://github.com/jcoyne))
- Don't bother doing a HEAD request to see if the object is new [\#81](https://github.com/samvera/ldp/pull/81) ([jcoyne](https://github.com/jcoyne))
- Update travis build matrix [\#80](https://github.com/samvera/ldp/pull/80) ([cbeer](https://github.com/cbeer))
- Remove the body method [\#79](https://github.com/samvera/ldp/pull/79) ([jcoyne](https://github.com/jcoyne))
- Add standard badges [\#78](https://github.com/samvera/ldp/pull/78) ([cjcolvar](https://github.com/cjcolvar))

## [v0.6.4](https://github.com/samvera/ldp/tree/v0.6.4) (2017-02-13)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.6.3...v0.6.4)

**Merged pull requests:**

- Raise Ldp::Conflict when creating existing resource [\#77](https://github.com/samvera/ldp/pull/77) ([jcoyne](https://github.com/jcoyne))

## [v0.6.3](https://github.com/samvera/ldp/tree/v0.6.3) (2017-01-13)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.6.2...v0.6.3)

**Merged pull requests:**

- Bump tested ruby versions [\#76](https://github.com/samvera/ldp/pull/76) ([jcoyne](https://github.com/jcoyne))
- Avoid an instantiation if subject is already a RDF::URI [\#75](https://github.com/samvera/ldp/pull/75) ([jcoyne](https://github.com/jcoyne))
- bump version, nothing in readme file needs to change related to version [\#74](https://github.com/samvera/ldp/pull/74) ([carrickr](https://github.com/carrickr))

## [v0.6.2](https://github.com/samvera/ldp/tree/v0.6.2) (2016-12-01)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.6.1...v0.6.2)

**Closed issues:**

- Resource should not send weak ETag in If-Match for delete or update [\#64](https://github.com/samvera/ldp/issues/64)

**Merged pull requests:**

- Use If-Unmodified-Since header instead of If-Match due to issue with strong vs. weak etags [\#72](https://github.com/samvera/ldp/pull/72) ([cjcolvar](https://github.com/cjcolvar))
- Handling 307 redirects [\#71](https://github.com/samvera/ldp/pull/71) ([escowles](https://github.com/escowles))

## [v0.6.1](https://github.com/samvera/ldp/tree/v0.6.1) (2016-08-18)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.6.0...v0.6.1)

**Merged pull requests:**

- Update rspec configuration with new default settings [\#68](https://github.com/samvera/ldp/pull/68) ([cbeer](https://github.com/cbeer))
- Remove unnecessary require [\#67](https://github.com/samvera/ldp/pull/67) ([jcoyne](https://github.com/jcoyne))

## [v0.6.0](https://github.com/samvera/ldp/tree/v0.6.0) (2016-08-11)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.5.0...v0.6.0)

**Closed issues:**

- Rename ETagMismatch error class [\#63](https://github.com/samvera/ldp/issues/63)
-  Ldp::HttpError \(STATUS: 401 [\#36](https://github.com/samvera/ldp/issues/36)

**Merged pull requests:**

- Precondition failed [\#66](https://github.com/samvera/ldp/pull/66) ([no-reply](https://github.com/no-reply))
- Bring dependencies up to date [\#65](https://github.com/samvera/ldp/pull/65) ([no-reply](https://github.com/no-reply))

## [v0.5.0](https://github.com/samvera/ldp/tree/v0.5.0) (2016-03-08)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.4.1...v0.5.0)

**Merged pull requests:**

- Factor Ldp::Response to wrap the raw http client responses [\#62](https://github.com/samvera/ldp/pull/62) ([cbeer](https://github.com/cbeer))
- Refactoring [\#61](https://github.com/samvera/ldp/pull/61) ([cbeer](https://github.com/cbeer))
- Update the build matrix [\#60](https://github.com/samvera/ldp/pull/60) ([jcoyne](https://github.com/jcoyne))
- Don't require a space between types. [\#56](https://github.com/samvera/ldp/pull/56) ([tpendragon](https://github.com/tpendragon))

## [v0.4.1](https://github.com/samvera/ldp/tree/v0.4.1) (2015-09-28)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.4.0...v0.4.1)

**Merged pull requests:**

- Ensure RDF is encoded as UTF-8 before sending it to the Turtle parser [\#55](https://github.com/samvera/ldp/pull/55) ([jcoyne](https://github.com/jcoyne))

## [v0.4.0](https://github.com/samvera/ldp/tree/v0.4.0) (2015-09-18)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.3.1...v0.4.0)

**Merged pull requests:**

- Add a Ldp::Conflict error type for 409 errors [\#54](https://github.com/samvera/ldp/pull/54) ([jcoyne](https://github.com/jcoyne))
- Instrument HTTP requests [\#53](https://github.com/samvera/ldp/pull/53) ([jcoyne](https://github.com/jcoyne))

## [v0.3.1](https://github.com/samvera/ldp/tree/v0.3.1) (2015-05-12)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.3.0...v0.3.1)

**Closed issues:**

- Getting graph from an existing RDFResource fails [\#47](https://github.com/samvera/ldp/issues/47)

**Merged pull requests:**

- Loosen restrictions from RDF::Graph [\#51](https://github.com/samvera/ldp/pull/51) ([tpendragon](https://github.com/tpendragon))

## [v0.3.0](https://github.com/samvera/ldp/tree/v0.3.0) (2015-04-03)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.2.3...v0.3.0)

**Closed issues:**

- Can't add implementation-specific omit/prefer headers. [\#49](https://github.com/samvera/ldp/issues/49)

**Merged pull requests:**

- Extract a value object to handle prefer headers. [\#50](https://github.com/samvera/ldp/pull/50) ([tpendragon](https://github.com/tpendragon))
- Ldp 47 [\#48](https://github.com/samvera/ldp/pull/48) ([barmintor](https://github.com/barmintor))

## [v0.2.3](https://github.com/samvera/ldp/tree/v0.2.3) (2015-02-24)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.2.2...v0.2.3)

**Merged pull requests:**

- Update README for Hydra [\#45](https://github.com/samvera/ldp/pull/45) ([awead](https://github.com/awead))
- Use the Apache 2.0 license for distribution [\#44](https://github.com/samvera/ldp/pull/44) ([awead](https://github.com/awead))
- fix overwrite of HTTP headers [\#38](https://github.com/samvera/ldp/pull/38) ([lasse-aagren](https://github.com/lasse-aagren))

## [v0.2.2](https://github.com/samvera/ldp/tree/v0.2.2) (2015-01-27)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.2.1...v0.2.2)

**Merged pull requests:**

- Don't attempt to remove a non-existant variable [\#43](https://github.com/samvera/ldp/pull/43) ([jcoyne](https://github.com/jcoyne))
- Minimize string allocations [\#42](https://github.com/samvera/ldp/pull/42) ([jcoyne](https://github.com/jcoyne))

## [v0.2.1](https://github.com/samvera/ldp/tree/v0.2.1) (2015-01-23)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.2.0...v0.2.1)

**Closed issues:**

- Calling .dup on a wrapped Faraday::Response, doesn't add the wrapped methods [\#39](https://github.com/samvera/ldp/issues/39)
- .new? and ActiveFedora .exist? are broken with misplaced 400 errors. [\#33](https://github.com/samvera/ldp/issues/33)
- save! always raises a GraphDifferenceException [\#22](https://github.com/samvera/ldp/issues/22)
- Round trip \(load-save\) causes a 500 error. [\#21](https://github.com/samvera/ldp/issues/21)
- orm.save with an rdf:type doesn't work with Fedora 4.0.0-alpha-3 [\#2](https://github.com/samvera/ldp/issues/2)

**Merged pull requests:**

- Allow \#dup of Ldp::Response. Fixes \#39 [\#40](https://github.com/samvera/ldp/pull/40) ([jcoyne](https://github.com/jcoyne))
- Binary should not inspect its content [\#35](https://github.com/samvera/ldp/pull/35) ([jcoyne](https://github.com/jcoyne))

## [v0.2.0](https://github.com/samvera/ldp/tree/v0.2.0) (2014-12-11)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.1.0...v0.2.0)

**Merged pull requests:**

- Cache 404 responses on HEAD requests [\#34](https://github.com/samvera/ldp/pull/34) ([jcoyne](https://github.com/jcoyne))
- Adds handling of HTTP 400 errors \(BadRequest\) [\#32](https://github.com/samvera/ldp/pull/32) ([flyingzumwalt](https://github.com/flyingzumwalt))

## [v0.1.0](https://github.com/samvera/ldp/tree/v0.1.0) (2014-12-04)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.10...v0.1.0)

## [v0.0.10](https://github.com/samvera/ldp/tree/v0.0.10) (2014-11-06)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.9...v0.0.10)

## [v0.0.9](https://github.com/samvera/ldp/tree/v0.0.9) (2014-10-31)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.8...v0.0.9)

## [v0.0.8](https://github.com/samvera/ldp/tree/v0.0.8) (2014-10-09)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.7...v0.0.8)

## [v0.0.7](https://github.com/samvera/ldp/tree/v0.0.7) (2014-08-04)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.6...v0.0.7)

## [v0.0.6](https://github.com/samvera/ldp/tree/v0.0.6) (2014-07-22)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.5...v0.0.6)

**Merged pull requests:**

- Changes to support RSpec 3 [\#31](https://github.com/samvera/ldp/pull/31) ([tpendragon](https://github.com/tpendragon))
- Adds requirements for Fedora's alpha-6 implementation of LDP. [\#30](https://github.com/samvera/ldp/pull/30) ([tpendragon](https://github.com/tpendragon))
- Adding Github as homepage [\#29](https://github.com/samvera/ldp/pull/29) ([jeremyf](https://github.com/jeremyf))

## [v0.0.5](https://github.com/samvera/ldp/tree/v0.0.5) (2014-04-24)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.4...v0.0.5)

## [v0.0.4](https://github.com/samvera/ldp/tree/v0.0.4) (2014-04-20)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.3...v0.0.4)

**Closed issues:**

- NPE calling Orm\#value on a new resource. [\#25](https://github.com/samvera/ldp/issues/25)
- Catch URI::InvalidURIError [\#10](https://github.com/samvera/ldp/issues/10)
- Handle object not found [\#6](https://github.com/samvera/ldp/issues/6)
- What are save and save! supposed to return? [\#5](https://github.com/samvera/ldp/issues/5)

**Merged pull requests:**

- Better save [\#26](https://github.com/samvera/ldp/pull/26) ([cbeer](https://github.com/cbeer))
- if we've already retrieved the body, we don't need to send another HEAD ... [\#24](https://github.com/samvera/ldp/pull/24) ([cbeer](https://github.com/cbeer))
- Head etag [\#20](https://github.com/samvera/ldp/pull/20) ([cbeer](https://github.com/cbeer))
- add instrumentation for LDP operations [\#19](https://github.com/samvera/ldp/pull/19) ([cbeer](https://github.com/cbeer))
- LDP::Resource\#create should accept a subject that is an existing absolut... [\#18](https://github.com/samvera/ldp/pull/18) ([cbeer](https://github.com/cbeer))
- Show the error message within the SaveException [\#17](https://github.com/samvera/ldp/pull/17) ([jcoyne](https://github.com/jcoyne))
- Add bin/ldp for issuing simple commands to an LDP endpoint [\#16](https://github.com/samvera/ldp/pull/16) ([cbeer](https://github.com/cbeer))
- Explain HttpErrors in the exception message [\#15](https://github.com/samvera/ldp/pull/15) ([jcoyne](https://github.com/jcoyne))
- Orm\#create should return a new Orm object [\#12](https://github.com/samvera/ldp/pull/12) ([jcoyne](https://github.com/jcoyne))
- check for HTTP status codes within Ldp::Client operations [\#11](https://github.com/samvera/ldp/pull/11) ([cbeer](https://github.com/cbeer))
- Ldp update [\#9](https://github.com/samvera/ldp/pull/9) ([cbeer](https://github.com/cbeer))

## [v0.0.3](https://github.com/samvera/ldp/tree/v0.0.3) (2014-04-16)

[Full Changelog](https://github.com/samvera/ldp/compare/v0.0.2...v0.0.3)

## [v0.0.2](https://github.com/samvera/ldp/tree/v0.0.2) (2014-03-21)

[Full Changelog](https://github.com/samvera/ldp/compare/b365fe0d8843b638f840db49bb8eac02b7194539...v0.0.2)

**Closed issues:**

- Can't load resources from Fedora 4 [\#1](https://github.com/samvera/ldp/issues/1)

**Merged pull requests:**

- Set arbitrary headers on a POST request [\#8](https://github.com/samvera/ldp/pull/8) ([jcoyne](https://github.com/jcoyne))
- Raise a NotFound error if the status is 404 [\#7](https://github.com/samvera/ldp/pull/7) ([jcoyne](https://github.com/jcoyne))
- added and fixed some tests, made it raise an exception on failed updates [\#4](https://github.com/samvera/ldp/pull/4) ([bmaddy](https://github.com/bmaddy))
- update readme.md [\#3](https://github.com/samvera/ldp/pull/3) ([bmaddy](https://github.com/bmaddy))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
