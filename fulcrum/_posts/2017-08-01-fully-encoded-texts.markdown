---
layout: post
title:  "Fulcrum Progress Report: Supporting Fully Encoded Texts"
date:   2017-08-01 16:46:30 -0400
author: Jeremy Morse
categories: blog
feature-image-file: "2017-08-01-fully-encoded-texts.png"
feature-image-alt: "Screenshot of Fulcrum's in-development EPUB Reader"
feature-image-caption: "A glimpse at Moby Dick represented in Fulcrum's EPUB Reader."
---
Today on [Fulcrum](https://www.fulcrum.org), you can see several examples of digital source material collections to complement a scholarly text, including richer, higher-resolution versions of images that appear in print, or supplemental material that could not be included in print yet provide vital context and insight into the research presented in monograph form.  The Fulcrum platform presents these materials with high standards of interactivity, accessibility, and discoverability, in an ecosystem that affords robust asset management and long-term preservation.

But our ambitions go much further: fully hosted, longform digital monographs, with digital enhancements integrated into the text itself.

Support for born-digital, fully encoded text, to be readable on the Fulcrum platform, is among the most complex technical challenges for Fulcrum development because it is the use case which is least supported in the [Samvera community](https://www.samvera.org). At the inception of our supporting Mellon grant, the community’s development efforts on Samvera had been focused on serving downloadable files in institutional repositories, media collections (audio/video and high-resolution images), and geodata. What little effort existed relating to readable texts exclusively pertained to page-turner interfaces for scanned physical volumes.

Within this context, the [University of Michigan Library](https://www.lib.umich.edu) convened a formal investigation into means and practices for adding full-text support to Samvera. The investigation focused on three areas of activity: data modeling for a complex digital work (text with embedded media and related supplemental material); indexing and structural search within the body of such a text; and the selection of text schema that both satisfies best practices for long-term preservation and which is compatible with existing open-source solutions for display within the browser.

In the course of the investigation, co-leaders Jeremy Morse (Director of Publishing Technology, Fulcrum Technical Lead and Grant co-PI) and Chris Powell (Coordinator, Encoded Text Services) were fortunate to find two useful collaborators. [Northeastern University’s TAPAS Project](http://www.tapasproject.org/), while quite specifically concerned with TEI-encoded manuscripts, was pursuing a similar strategy with regards to their Samvera data model, which affirmed our approach.  Closer to home, HathiTrust has moved up its timetable for acceptance of EPUBs in support of the Mellon/NEH Humanities Open Book Program. While the ingest and data modeling requirements of Samvera and HathiTrust are quite different, our two projects share a significant overlap in the areas of preservation specification and validation, indexing and search, and display. We have begun coordinating our efforts to share both development resources and technology solutions for these areas in order to maximize productivity, maintainability, and efficacy.

The investigation is now complete and active development is underway.  The culmination of the investigation can be summarized as follows:

## File Format and Display
Fulcrum has aligned with [HathiTrust](https://www.hathitrust.org) in selecting [EPUB 3.1](http://www.idpf.org/epub/31/spec/epub-spec.html) as both a preservation and display format and working jointly in this pursuit.  MLibrary Digital Preservation Office has drafted a preservation profile for the EPUB 3.1 format, and the Architecture and Engineering unit is developing validation software for use during ingest processes. HathiTrust and Fulcrum are actively co-developing a [web-based EPUB reader](https://github.com/mlibrary/cozy-sun-bear) that will be adaptable for use by either platform.

## Data Model
Based on [PCDM 2.0](https://github.com/duraspace/pcdm/wiki), Fulcrum will use a data model that is intentionally reductionist; its responsibility is limited to enabling the grouping, access management, metadata-level search, and retrieval of the text and any related media assets. Any knowledge of the complex structure, hierarchy, or ordering of these constituent parts of a complex digital work are expressed within the EPUB file; Samvera will hand off responsibilities for full text search and display to helper apps which know the internals of the EPUB document. With this modular approach, the same core architecture could be used for other formats besides EPUB.

## Indexing and Search
While Samvera’s native [Blacklight Solr index](http://projectblacklight.org/) will support the search of metadata records for all texts and media assets, work will begin soon on a separate full-text index of the EPUB.  As our initial use case is a collection with a single book, our first efforts will support full text search within a book (as opposed to across a corpus), and search results will return the most relevant chapters.  (We may later explore the possibility of returning the most relevant pages, but not all reflowable EPUBs will have page boundaries marked, whereas the EPUB format is natively structured by chapter.)

In future posts, we will discuss how media assets will be integrated with the text in what we’re calling the “Fulcrumized” ebook.  Keep watching for updates!
