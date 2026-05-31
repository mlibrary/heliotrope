# History of hydra-editor releases

## 5.0.1
* 2019-09-30: Update the dependency for the `simple_form` Gem to 5.0.x releases

## 5.0.0
* 2019-03-26: Added CodeClimate [@cjcolvar]
* 2019-03-26: Updates testing for Rails support to releases 5.2.2, 5.1.6.1, and 5.0.7.1 [@cjcolvar]
* 2019-03-26: Updates simple_form to releases 4.1.0 (or later) [@cjcolvar]
* 2019-03-26: Updates engine_cart to release 2.2 [@cjcolvar]
* 2018-08-14: Updates the repository documentation in compliance with the guidelines of the Core Component Maintenance Working Group [@botimer]

## 4.0.2
* 2018-05-10: MultiValue gets values from object methods and attributes [afred]

## 4.0.1
* 2018-04-25: Updated the gemspec for authors, email, and homepage

## 4.0.0
* 2018-04-25: Released after testing

## 4.0.0.rc1
* 2018-03-21: Updates HydraEditor::Form.model_attributes. [dchandekstark]
* 2018-03-21: Replace `Hydra::Presenter#to_model` delegation with `self` [no-reply]

## 3.4.0.beta
* 2018-03-05: Change FactoryGirl dependency to FactoryBot [no-reply]
* 2018-03-05: Restrict `simple_form` to `<= 3.5.0` [no-reply]

## 3.3.2
* 2017-05-23: Backport Idempotent DOM manipulation [jcoyne]
* 2017-05-23: Testing on supported version of rails. Fixes #135 [jcoyne]
* 2017-05-23: Make DOM manipulations idempotent. [jcoyne]
* 2017-05-09: Update travis build matrix [cbeer]

## 3.3.1
* 2017-05-04: Use ActiveModel::Naming to find partials [jcoyne]
* 2017-05-04: Remove unused method [jcoyne]

## 3.2.1
* 2017-05-01: Don't repeat the inputTypeClass value [jcoyne]

## 3.2.0
* 2017-04-13: Use almond 0.1.0 [jcoyne]
* 2017-04-10: Allow setting a custom field_metadata_service [jcoyne]
* 2016-12-08: Use first label to avoid smushing nested labels in more complex fields [hackmastera]
* 2016-09-19: Test for adding input or textarea child fields [awead]
* 2016-09-19: Use class selector for specifying a field's children [awead]

## 3.1.2
* 2016-09-20: Clean Gemfile [jcoyne]

## 3.1.1
* 2016-09-13: Update `engine_cart` and `ActiveTriples` [jcoyne]
* 2016-08-24: Optimize form field partial lookups [cbeer]

## 3.1.0
* 2016-08-08: Uses the `rdf-vocab` Gem for predicates [jcoyne]
* 2016-08-08: Silence Devise deprecation in test configuration [atz]
* 2016-08-08: Introduce support for Rails 5 releases [jcoyne]

## 3.0.0.beta1
* 2016-06-23: Delegate `model_name` to the `model` attribute [jcoyne]
* 2016-06-23: Converts `FieldManager` to ECMAScript 6 [jcoyne]
* 2016-05-19: Improve usability and a11y for multi-valued fields [jcoyne]
* 2016-04-28: Permit the HTML partials to be configurable [jcoyne]
* 2016-04-28: Replace the `simple_form` bootstrap config. [jcoyne]
* 2016-04-28: Update the development dependencies [jcoyne]

## 2.0.0

* 2016-04-07: Updates the usage of `property` method [jcoyne]
* 2016-04-07: Adds delegate method `#new_record` [jcoyne]
* 2016-03-28: Updates solr_wrapper and fcrepo_wrapper [atz]
* 2016-03-28: Updates Rubocop [atz]
* 2016-03-24: Promotion from samvera-labs Organization

## 1.2.0
* 2016-01-18: Support Blacklight 6 [Justin Coyne]

## 1.1.0
* 2015-10-09: multiple? shouldn't raise errors when confronted with non-properties [Justin Coyne]
* 2015-09-17: Add an instance method version of multiple? [Justin Coyne]
* 2015-09-17: Update build matrix [Justin Coyne]
* 2015-09-17: Make add and remove button the same size [Justin Coyne]
* 2015-09-17: Use property instead of deprecated has_attributes [Justin Coyne]
* 2015-09-17: Pin bootstrap-sass to 3.3.4.1 for rails 4.1 build [Justin Coyne]
* 2015-06-10: Use html-safe translation to avoid raw() call [Jeremy Echols]
* 2015-04-23: Add <kbd> tags for more semantic form instructions [Jeremy Echols]
* 2015-04-21: Allow overriding jetty port [Jeremy Echols]
* 2015-04-21: Add form instructions for screen readers [Jeremy Echols]
* 2015-04-17: Don't hardcode a version of hydra-head in the test app [Justin Coyne]
* 2015-04-16: Split option-building from field-building [Jeremy Echols]
* 2015-04-14: Make [ENTER] default to submit the form [Jeremy Echols]

## 1.0.3
* 2015-04-02: Updated README with info on how to set form labels [val99erie]
* 2015-03-30: Add documentation to Form#model_attributes. (ci skip) [Justin Coyne]
* 2015-03-30: Presenter should be able to know the cardinality of associations [Justin Coyne]

## 1.0.2
* Update javascript to be more selective about which fields cause an error when blank

## 0.0.2
* Requiring active-fedora >= 6.3.0 in order to have the .required? method on ActiveFedora::Base:q

## 0.1.0
* RecordsControllerBehavior made more easily reusable outside of RecordsController.

### 0.1.1
* Correctly account for modifications made by initialize_fields when processing form data. Fixes #14.
