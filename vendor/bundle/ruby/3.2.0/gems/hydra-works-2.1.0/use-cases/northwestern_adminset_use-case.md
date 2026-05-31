Northwestern AdminSet Use Case
Sponsor: @julesies

Given an administrative grouping of items 
As an administrative unit that is ultimately responsible for managing. The set itself helps to manage the items within it. 
I want to maintain the following relationships of an AdminSet.
  Can not contain other sets of any kind 
  Only staff with permission to create or manage an admin set can do so
  All items must be in an AdminSet (there could be a default collection)
  Items can only be in one AdminSet
  Admin sets contain a set of default values (permissions, metadata, etc) that can be applied to new objects in the set
  Any changes to default settings should not automatically change all items in a collection but prompt the user with options
  Can be faceted for discovery (but it would be nice if that was optional)
  Order does not matter
So that an Administrative Set's primary use is to manage distinct collections of digital objects over time

Here are some example object we need to represent, and their characteristics, from least to most complex.

AdminSet
