# RDF::RDFa reader/writer

[RDFa][RDFa 1.1 Core] parser for RDF.rb.

[![Gem Version](https://badge.fury.io/rb/rdf-rdfa.svg)](https://badge.fury.io/rb/rdf-rdfa)
[![Build Status](https://github.com/ruby-rdf/rdf-rdfa/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-rdfa/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/rdf-rdfa/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-rdfa?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## DESCRIPTION
RDF::RDFa is an RDFa reader and writer for Ruby using the [RDF.rb][RDF.rb] library suite.

## FEATURES
RDF::RDFa parses [RDFa][RDFa 1.1 Core] into statements or triples.

* Fully compliant RDFa 1.1 parser.
* Template-based Writer to generate XHTML+RDFa.
  * Writer uses user-replaceable [Haml][Haml] -based templates to generate RDFa.
* If available, uses [Nokogiri][] for parsing HTML/SVG, falls back to REXML otherwise.

Install with `gem install rdf-rdfa`

### Pure Ruby
In order to run as pure ruby (not requiring any C modules), this gem does not directly depend on [Nokogiri][]
and falls back to using REXML.
As REXML is not really an HTML parsing library, the results will only be useful if the HTML is well-formed.
For best performance, install the [Nokogiri][] gem as well.

### Important changes from previous versions
RDFa is an evolving standard, undergoing some substantial recent changes partly due to perceived competition
with Microdata. As a result, the RDF Webapps working group is currently looking at changes in the processing model for RDFa. These changes are now being tracked in {RDF::RDFa::Reader}:

#### RDFa 1.1 Lite
This version fully supports the limited syntax of [RDFa Lite 1.1][]. This includes the ability to use `@property` exclusively.

#### Vocabulary Expansion
One of the issues with vocabularies was that they discourage re-use of existing vocabularies when terms from several vocabularies are used at the same time. As it is common (encouraged) for RDF vocabularies to form sub-class and/or sub-property relationships with well defined vocabularies, the RDFa vocabulary expansion mechanism takes advantage of this.

As an optional part of RDFa processing, an RDFa processor will perform limited
[OWL 2 RL Profile entailment](https://www.w3.org/TR/2009/REC-owl2-profiles-20091027/#Reasoning_in_OWL_2_RL_and_RDF_Graphs_using_Rules),
specifically rules prp-eqp1, prp-eqp2, cax-sco, cax-eqc1, and
cax-eqc2. This causes sub-classes and sub-properties of type and property IRIs to be added
to the output graph.

{RDF::RDFa::Reader} implements this using the `#expand` method, which looks for `rdfa:usesVocabulary` properties within the output graph and performs such expansion. See an example in the usage section.

#### Experimental support for rdfa:copy template expansion
RDFa 1.1 is just about an exact super-set of microdata, except for microdata's
`@itemref` feature. Experimental support is added for `rdfa:copy` and `rdfa:Pattern` to get a similar effect using expansion. To use this,
reference another resource using `rdfa:copy`. If that resource has the type
`rdfa:Pattern`, the properties defined there will be added to the resource
containing the `rdfa:copy`, and the pattern and `rdfa:copy` will be removed
from the output.

For example, consider the following:

    <div>
      <div typeof="schema:Person">
        <link property="rdfa:copy" resource="_:a"/>
      </div>
      <p resource="_:a" typeof="rdfa:Pattern">Name: <span property="schema:name">Amanda</span></p>
    </div>

if run with vocabulary expansion, this will result in the following Turtle:

    @prefix schema: <http://schema.org/> .
    [a schema:Person; schema:name "Amanda"] .


#### RDF Collections (lists)
One significant RDF feature missing from RDFa was support for ordered collections, or lists. RDF supports this with special properties `rdf:first`, `rdf:rest`, and `rdf:nil`, but other RDF languages have first-class support for this concept. For example, in [Turtle][Turtle], a list can be defined as follows:

    [ a schema:MusicPlayList;
      schema:name "Classic Rock Playlist";
      schema:numTracks 5;
      schema:tracks (
        [ a schema:MusicRecording; schema:name "Sweet Home Alabama";       schema:byArtist "Lynard Skynard"]
        [ a schema:MusicRecording; schema:name "Shook you all Night Long"; schema:byArtist "AC/DC"]
        [ a schema:MusicRecording; schema:name "Sharp Dressed Man";        schema:byArtist "ZZ Top"]
        [ a schema:MusicRecording; schema:name "Old Time Rock and Roll";   schema:byArtist "Bob Seger"]
        [ a schema:MusicRecording; schema:name "Hurt So Good";             schema:byArtist "John Cougar"]
      )
    ]

defines a playlist with an ordered set of tracks. RDFa adds the @inlist attribute, which is used to identify values (object or literal) that are to be placed in a list. The same playlist might be defined in RDFa as follows:

    <div vocab="http://schema.org/" typeof="MusicPlaylist">
      <span property="name">Classic Rock Playlist</span>
      <meta property="numTracks" content="5"/>

      <div rel="tracks" inlist="">
        <div typeof="MusicRecording">
          1.<span property="name">Sweet Home Alabama</span> -
          <span property="byArtist">Lynard Skynard</span>
         </div>

        <div typeof="MusicRecording">
          2.<span property="name">Shook you all Night Long</span> -
          <span property="byArtist">AC/DC</span>
        </div>

        <div typeof="MusicRecording">
          3.<span property="name">Sharp Dressed Man</span> -
          <span property="byArtist">ZZ Top</span>
        </div>

        <div typeof="MusicRecording">
          4.<span property="name">Old Time Rock and Roll</span>
          <span property="byArtist">Bob Seger</span>
        </div>

        <div typeof="MusicRecording">
          5.<span property="name">Hurt So Good</span>
          <span property="byArtist">John Cougar</span>
        </div>
      </div>
    </div>

This basically does the same thing, but places each track in an rdf:List in the defined order.

#### Magnetic @about/@typeof
The @typeof attribute has changed; previously, it always created a new subject, either using a resource from @about, @resource and so forth. This has long been a source of errors for people using RDFa. The new rules cause @typeof to bind to a subject if used with @about, otherwise, to an object, if either used alone, or in combination with some other resource attribute (such as @href, @src or @resource).

For example:

    <div typeof="foaf:Person" about="https://greggkellogg.net/foaf#me">
      <p property="name">Gregg Kellogg</span>
      <a rel="knows" typeof="foaf:Person" href="https://manu.sporny.org/#this">
        <span property="name">Manu Sporny</span>
      </a>
    </div>

results in

    <https://greggkellogg.net/foaf#me> a foaf:Person;
      foaf:name "Gregg Kellogg";
      foaf:knows <https://manu.sporny.org/#this> .
    <https://manu.sporny.org/#this> a foaf:Person;
      foaf:name "Manu Sporny" .

Note that if the explicit @href is not present, i.e.,

    <div typeof="foaf:Person" about="https://greggkellogg.net/foaf#me">
      <p property="name">Gregg Kellogg</span>
      <a href="knows" typeof="foaf:Person">
        <span property="name">Manu Sporny</span>
      </a>
    </div>

this results in

    <https://greggkellogg.net/foaf#me> a foaf:Person;
      foaf:name "Gregg Kellogg";
      foaf:knows [ 
            a foaf:Person;
            foaf:name "Manu Sporny" 
      ].


### Support for embedded RDF/XML
If the document includes embedded RDF/XML, as is the case with many SVG documents, and the RDF::RDFXML gem is installed, the reader will add extracted triples to the default graph.

For example:

    <?xml version="1.0" encoding="UTF-8"?>
    <svg width="12cm" height="4cm" viewBox="0 0 1200 400"
        xmlns:dc="http://purl.org/dc/terms/"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xml:base="http://example.net/"
        xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny">
      <desc property="dc:description">A yellow rectangle with sharp corners.</desc>
      <metadata>
        <rdf:RDF>
          <rdf:Description rdf:about="">
            <dc:title>Test 0304</dc:title>
          </rdf:Description>
        </rdf:RDF>
      </metadata>
      <!-- Show outline of canvas using 'rect' element -->
      <rect x="1" y="1" width="1198" height="398"
            fill="none" stroke="blue" stroke-width="2"/>
      <rect x="400" y="100" width="400" height="200"
            fill="yellow" stroke="navy" stroke-width="10"  />
    </svg>

generates the following turtle:

    @prefix dc: <http://purl.org/dc/terms/> .

  	<http://example.net/> dc:title "Test 0304" ;
  	  dc:description "A yellow rectangle with sharp corners." .

### Support for embedded N-Triples or Turtle
If the document includes a `&lt;script&gt;` element having an `@type` attribute whose value matches that of a loaded RDF reader (text/ntriples and text/turtle are loaded if they are available), the data will be extracted and added to the default graph. For example:

    <html>
      <body>
        <script type="text/turtle"><![CDATA[
           @prefix foo:  <http://www.example.com/xyz#> .
           @prefix gr:   <http://purl.org/goodrelations/v1#> .
           @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
           @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

           foo:myCompany
             a gr:BusinessEntity ;
             rdfs:seeAlso <http://www.example.com/xyz> ;
             gr:hasLegalName "Hepp Industries Ltd."^^xsd:string .
        ]]></script>
      </body>
    </html>

generates the following Turtle:

```
   @prefix foo:  <http://www.example.com/xyz#> .
   @prefix gr:   <http://purl.org/goodrelations/v1#> .
   @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
   @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

   foo:myCompany
     a gr:BusinessEntity ;
     rdfs:seeAlso <http://www.example.com/xyz> ;
     gr:hasLegalName "Hepp Industries Ltd."^^xsd:string .
```

### Support for Role Attribute
The processor will generate RDF triples consistent with the [Role Attr][] specification.

    <div id="heading1" role="heading">
      <p>Some contents that are a header</p>
    </div>

generates the following Turtle:

    @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
    <#heading1> xhv:role xhv:heading.

### Support for microdata
The RDFa reader will call out to `RDF::Microdata::Reader`, if an `@itemscope` attribute is detected, and the microdata reader is loaded. This avoids a common problem when pages contain both microdata and RDFa, and only one processor is run.

### Support for value property
In an [RDFA+HTML Errata](https://www.w3.org/2001/sw/wiki/RDFa_1.1._Errata#Using_.3Cdata.3E.2C_.3Cinput.3E_and_.3Cli.3E_along_with_.40value), it was suggested that the `@value` attribute could be parsed to obtain a numeric literal; this is consistent with how it's treated in microdata+rdfa. This processor now parses the value of an `@value` property to determine if it is an `xsd:integer`, `xsd:float`, or `xsd:double`, and uses a plain literal otherwise. The datatype can be overriden using the `@datatype` attribute.
## Usage

### Reading RDF data in the RDFa format

    graph = RDF::Graph.load("etc/doap.html", format: :rdfa)

### Reading RDF data with vocabulary expansion

    graph = RDF::Graph.load("etc/doap.html", format: :rdfa, vocab_expansion: true)

or

    graph = RDF::RDFa::Reader.open("etc/doap.html").expand

### Reading Processor Graph

    graph = RDF::Graph.load("etc/doap.html", format: :rdfa, rdfagraph: :processor)

### Reading Both Processor and Output Graphs

    graph = RDF::Graph.load("etc/doap.html", format: :rdfa, rdfagraph: [:output, :processor])

### Writing RDF data using the XHTML+RDFa format

    require 'rdf/rdfa'
    
    RDF::RDFa::Writer.open("etc/doap.html") do |writer|
      writer << graph
    end

Note that prefixes may be chained between Reader and Writer, so that the Writer will
use the same prefix definitions found during parsing:

    prefixes = {}
    graph = RDF::Graph.load("etc/doap.html", prefixes: prefixes)
    puts graph.dump(:rdfa, prefixes: prefixes)

### Template-based Writer
The RDFa writer uses [Haml][Haml] templates for code generation. This allows
fully customizable RDFa output in a variety of host languages. The [default
template]({RDF::RDFa::Writer::DEFAULT_HAML}) generates human readable HTML5
output. A [minimal template]({RDF::RDFa::Writer::MIN_HAML}) generates HTML,
which is not intended for human consumption.

To specify an alternative Haml template, consider the following:

    require 'rdf/rdfa'
    
    RDF::RDFa::Writer.buffer(haml: RDF::RDFa::Writer::MIN_HAML) << graph

The template hash defines four Haml templates:

*   _doc_: Document Template, takes an ordered list of _subject_s and yields each one to be rendered. From {RDF::RDFa::Writer#render_document}:

    {include:RDF::RDFa::Writer#render_document}

    This template takes locals _lang_, _prefix_, _base_, _title_ in addition to _subjects_
    to create output similar to the following:
      
        <!DOCTYPE html>
        <html prefix='xhv: http://www.w3.org/1999/xhtml/vocab#' xmlns='http://www.w3.org/1999/xhtml'>
          <head>
            <base href="http://example/">
            <title>Document Title</title>
          </head>
          <body>
            ...
          </body>
        </html>
      
    Options passed to the Writer are used to supply _lang_ and _base_ locals.
    _prefix_ is generated based upon prefixes found from the default profiles, as well
    as those provided by a previous Reader. _title_ is taken from the first top-level subject
    having an appropriate title property (as defined by the _heading\_predicates_ option).

*   _subject_: Subject Template, take a _subject_ and an ordered list of _predicate_s and yields
    each _predicate_ to be rendered. From {RDF::RDFa::Writer#render_subject}:
    
    {include:RDF::RDFa::Writer#render_subject}
    
    The template takes locals _rel_ and _typeof_ in addition to _predicates_ and _subject_ to
    create output similar to the following:
    
        <div resource="http://example/">
          ...
        </div>

    Note that if _typeof_ is defined, in this template, it will generate a textual description.
    
*   _property\_value_: Property Value Template, used for predicates having a single value; takes
    a _predicate_, and a single-valued Array of _objects_. From {RDF::RDFa::Writer#render_property}:

    {include:RDF::RDFa::Writer#render_property}
   
    In addition to _predicate_ and _objects_, the template takes _inlist_ to indicate that the
    property is part of an `rdf:List`.

    Also, if the predicate is identified as a _heading predicate_ (via _:heading\_predicates_ option),
    it will generate a heading element, and may use the value as the document title.

    Each _object_ is yielded to the calling block, and the result is rendered, unless nil.
    Otherwise, rendering depends on the type of _object_. This is useful for recursive document
    descriptions.

    Creates output similar to the following:
    
        <div class='property'>
          <span class='label'>
            xhv:alternate
          </span>
          <a property='xhv:alternate' href='http://rdfa.info/feed/'>http://rdfa.info/feed/</a>
        </div>
    
    Note the use of methods defined in {RDF::RDFa::Writer} useful in rendering the output.
    
*   _property\_values_: Similar to _property\_value_, but for predicates having more than one value.
    Locals are identical to _property\_values_, but _objects_ is expected to have more than one value. Described further in {RDF::RDFa::Writer#render_property}.
    
    In this case, and unordered list is used for output. Creates output similar to the following:
    
        <div class='property'>
          <span class='label'>
            xhv:bookmark
          </span>
          <ul rel='xhv:bookmark'>
            <li>
              <a href='http://rdfa.info/2009/12/12/oreilly-catalog-uses-rdfa/'>
                http://rdfa.info/2009/12/12/oreilly-catalog-uses-rdfa/
              </a>
            </li>
              <a href='http://rdfa.info/2010/05/31/new-rdfa-checker/'>
                http://rdfa.info/2010/05/31/new-rdfa-checker/
              </a>
            </li>
          </ul>
        </div>
    If _property\_values_ does not exist, repeated values will be replecated
    using _property\_value_.
* Type-specific templates.
  To simplify generation of different output types, the
  template may contain a elements indexed by a URI. When a subject with an rdf:type
  matching that URI is found, subsequent Haml definitions will be taken from
  the associated Hash. For example:
  
    {
      document: "...",
      subject: "...",
      :property\_value => "...",
      :property\_values => "...",
      RDF::URI("http://schema.org/Person") => {
        subject: "...",
        :property\_value => "...",
        :property\_values => "...",
      }
    }

## Dependencies
* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [Haml](https://rubygems.org/gems/haml) (>- 5.2, < 7)
* [HTMLEntities](https://rubygems.org/gems/htmlentities) (~> 4.3)
* Soft dependency on [Nokogiri](https://rubygems.org/gems/nokogiri) (~> 1.12)

## Documentation
Full documentation available on [Rubydoc.info][RDFa doc]

### Principle Classes
* {RDF::RDFa::Format}
* {RDF::RDFa::Reader}
  * {RDF::RDFa::Reader::Nokogiri}
  * {RDF::RDFa::Reader::REXML}
* {RDF::RDFa::Context}
* {RDF::RDFa::Expansion}
* {RDF::RDFa::Writer}

## TODO
* Add support for LibXML and REXML bindings, and use the best available
* Consider a SAX-based parser for improved performance

## Resources
* [RDF.rb][RDF.rb]
* [Distiller](http://rdf.greggkellogg.net/distiller)
* [Documentation][RDFa doc]
* [History](file:History.md)
* [RDFa 1.1 Core][RDFa 1.1 Core]
* [XHTML+RDFa 1.1][XHTML+RDFa 1.1]
* [RDFa-test-suite](https://rdfa.info/test-suite/              "RDFa test suite")

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributors
* [Nicholas Humfrey](https://github.com/njh) - <https://njh.me/>

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying [UNLICENSE](UNLICENSE) file.

## FEEDBACK

* gregg@greggkellogg.net
* <https://rubygems.org/rdf-rdfa>
* <https://github.com/ruby-rdf/rdf-rdfa>
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

[RDF.rb]:           https://rubygems.org/gems/rdf
[YARD]:             https://yardoc.org/
[YARD-GS]:          https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[RDFa 1.1 Core]:    https://www.w3.org/TR/2012/REC-rdfa-core-20120607/                    "RDFa 1.1 Core"
[RDFa Lite 1.1]:    https://www.w3.org/TR/2012/REC-rdfa-lite-20120607/                    "RDFa Lite 1.1"
[XHTML+RDFa 1.1]:   https://www.w3.org/TR/2012/REC-xhtml-rdfa-20120607/                   "XHTML+RDFa 1.1"
[HTML+RDFa 1.1]:    https://www.w3.org/TR/rdfa-in-html/                                   "HTML+RDFa 1.1"
[RDFa-test-suite]:  https://rdfa.info/test-suite/                                         "RDFa test suite"
[Role Attr]:        https://www.w3.org/TR/role-attribute/                                 "Role Attribute"
[RDFa doc]:         https://ruby-rdf.github.io/rdf-rdfa/frames
[Haml]:             https://haml-lang.com/
[Turtle]:           https://www.w3.org/TR/2011/WD-turtle-20110809/
[Nokogiri]:         https://www.nokogiri.org
