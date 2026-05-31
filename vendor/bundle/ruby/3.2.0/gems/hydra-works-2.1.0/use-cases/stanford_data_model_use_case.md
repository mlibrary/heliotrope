# Stanford hierarchical data modeling

Sponsor: @atz

Tip o' the hat to the [Princeton cases](princeton_book_use_case.md) that are sufficient for our most common cases.

We currently have Collections, Items and Files.  Items belong to exactly 1 Collection and have 0..n Files.
Our approach is mappable to the proposed [Component model](https://cloud.githubusercontent.com/assets/856924/4593133/4ef830c4-5083-11e4-9ec7-261a9483eb7a.png)
Other groupings/lists will be discussed separately.

Here we'll introduce some complexities.

## Access/Rights

At construction, the work acquires overridable default rights from its Collection membership.  
We do optionally apply access rights at the (file) leaf node level, where an individual file might be, for example, raw documentary audio of an event, i.e. source material for the work.

## Multi-phase digitization

To the baseline:
```
Given a book with many pages, and many images of each page  
As a repository comprised in part of digitized books and manuscripts  
I want to maintain the relationships between images of a page and technical, 
    descriptive, and provenance metadata about each image
And I want to maintain sorting, label, and other metadata, as well as files
    that represent the whole object in one place
So that I can have multiple images of a page tied to one instance of a model 
    without relying on naming conventions (e.g. jp2_md5_checksum)
```
Add:
```
INCLUDING multiple images of the same page generated at different times via separate scans.
```

Note:
 * format is not enough to distinguish the various page-images
 * it should be possible to add `1..n` additional scan-image file(s) to a page Component
    * ideally via metadata that identifies the page being represented (because newfile also represents work:$id, page:34)
        * instead of just (or in addition to) explicitly saying attach newfile to component:$cid
 * We agree work must also take attachment of `0..n` file(s), not just the page components.  Most commonly this would be the big PDF representing the whole work (or more than one page).
    * However, a composite work-level file may be composed from partial scans, rather than page-files being decomposed from a big scan.
        * Some day (or for certain means of accessing certain media, e.g. streaming audio) this composite might be assembled on the fly rather than precomposed.


## Order

 * Order of components or subcomponents is essential
    * If you have a bunch of pages, you need to be able to present them in order.  That order shouldn't change if additional page-images of already populated pages are added.
 * Order of files (leaf nodes) is important but context-dependent:
    * In this case one version of order is just the ability to prefer one file of a given format vs others, e.g. `getBestImageForCompositing(["tiff","jp2", "jpg"])`

## Technical Reports, Versioning

Some reports are republished in a versioned sequence.  They are substantially the same work with updates or corrections.  The work is at the report title level, with a component for the version
and further subcomponents for pages.

## Problematic Cases

These are not immediate requirements but are targets for future integration.

### Book Sets, Box Sets, e.g. Atlas of Maps or Art Book

An Art Book contains images representing artistic works where the individual Component's descriptive metadata is likely of equivalent or greater interest than
its presence in the publication.  This case is particularly strong when digitization policy supports targeting of individual pages on demand (say, Pablo Picaso, "Blue Nude").

Similarly, for descriptive purposes, a map is more tightly bound to its creator than to its appearance in a given atlas.  
Will attempt to flesh out via concrete example.

### Series

Classic problem, hasn't been discussed much.  Presumed out of scope for works modeling.  

### Government Documents

Similar to series.

### Dataset

Institutionally generated or acquired from external source.

Not necessarily including related publication.  There may or may not be an accompanying paper or article.  If existing, the publication may be part of the 
Hydra repository or external.

Needs to be able to attach to part of a research-work.  Defer on modeling domain-specific full hierarchical depth.

