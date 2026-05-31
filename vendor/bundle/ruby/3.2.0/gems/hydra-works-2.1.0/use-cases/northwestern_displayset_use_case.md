Northwestern DisplaySets Use Case
Sponsor: @julesies

Given a Display Set is an intellectual grouping of items that a curator (or person who has the rights to) creates
As an aid in the discovery and presentation of collections of materials. 
The display set is distinct from User Collections because it's primary purpose is the visual display of Display Sets. The Display Set is distinct from an Admin Set because the Display Set itself does not affect items within it. 
I want to maintain the folllowing relationships of a DisplaySet.
  Supports hierarchical display of collections in facets
  Items in a repository may be in more than one Display Set
  Items in a repository do not have to be in a Display Set
  Display Sets can contain other Display Sets
So that a curator makes a library collection of Maps of Africa, some of which are contained in different collections. 
The Biology Department has a collection of departmental masters theses and wants viewers to navigate the collections via facets like this:
  Biology Department
    Master's Theses
      1972
      1973
      1974

Here are some example object we need to represent, and their characteristics, from least to most complex.

DisplaySet
User Collection
