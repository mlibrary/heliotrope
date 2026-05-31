# coding: utf-8
require_relative 'spec_helper'

describe YAML_LD::API do
  let(:logger) {RDF::Spec.logger}

  describe ".frame" do
    {
      "exact @type match": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@type": ex:Type1
        ),
        input: %(
        - "@context":
            ex: http://example.org/
          "@id": ex:Sub1
          "@type": ex:Type1
        - "@context":
            ex: http://example.org/
          "@id": ex:Sub2
          "@type": ex:Type2
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub1
          "@type": ex:Type1
        )
      },
      "wildcard @type match": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@type": {}
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            "@type": ex:Type1
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            "@type": ex:Type2
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@graph":
          - "@id": ex:Sub1
            "@type": ex:Type1
          - "@id": ex:Sub2
            "@type": ex:Type2
        )
      },
      "match none @type match": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@type": []
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            "@type": ex:Type1
            ex:p: Foo
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            ex:p: Bar
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub2
          ex:p: Bar
        )
      },
      "multiple matches on @type": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@type": ex:Type1
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            "@type": ex:Type1
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            "@type": ex:Type1
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub3
            "@type":
            - ex:Type1
            - ex:Type2
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@graph":
          - "@id": ex:Sub1
            "@type": ex:Type1
          - "@id": ex:Sub2
            "@type": ex:Type1
          - "@id": ex:Sub3
            "@type":
            - ex:Type1
            - ex:Type2
        )
      },
      "single @id match": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub1
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            "@type": ex:Type1
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            "@type": ex:Type2
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub1
          "@type": ex:Type1
        )
      },
      "multiple @id match": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@id":
            - ex:Sub1
            - ex:Sub2
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            "@type": ex:Type1
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            "@type": ex:Type2
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub3
            "@type": ex:Type3
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@graph":
          - "@id": ex:Sub1
            "@type": ex:Type1
          - "@id": ex:Sub2
            "@type": ex:Type2
        )
      },
      "wildcard and match none": {
        frame: %(
          "@context":
            ex: http://example.org/
          ex:p: []
          ex:q: {}
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            ex:q: bar
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            ex:p: foo
            ex:q: bar
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub1
          ex:p:
          ex:q: bar
        )
      },
      "match on any property if @requireAll is false": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@requireAll": false
          ex:p: {}
          ex:q: {}
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            ex:p: foo
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            ex:q: bar
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@graph":
          - "@id": ex:Sub1
            ex:p: foo
            ex:q:
          - "@id": ex:Sub2
            ex:p:
            ex:q: bar
        )
      },
      "match on defeaults if @requireAll is true and at least one property matches": {
        frame: %(
          "@context":
            ex: http://example.org/
          "@requireAll": true
          ex:p:
            "@default": Foo
          ex:q:
            "@default": Bar
        ),
        input: %(
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            ex:p: foo
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub2
            ex:q: bar
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub3
            ex:p: foo
            ex:q: bar
          - "@context":
              ex: http://example.org/
            "@id": ex:Sub4
            ex:r: baz
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@graph":
          - "@id": ex:Sub1
            ex:p: foo
            ex:q: Bar
          - "@id": ex:Sub2
            ex:p: Foo
            ex:q: bar
          - "@id": ex:Sub3
            ex:p: foo
            ex:q: bar
        )
      },
      "issue #40 - example": {
        frame: %(
          "@context":
            "@version": 1.1
            "@vocab": https://schema.org/
          "@type": Person
          "@requireAll": true
          givenName: John
          familyName: Doe
        ),
        input: %(
          "@context":
            "@version": 1.1
            "@vocab": https://schema.org/
          "@graph":
          - "@id": '1'
            "@type": Person
            name: John Doe
            givenName: John
            familyName: Doe
          - "@id": '2'
            "@type": Person
            name: Jane Doe
            givenName: Jane
        ),
        output: %(
          "@context":
            "@version": 1.1
            "@vocab": https://schema.org/
          "@id": '1'
          "@type": Person
          familyName: Doe
          givenName: John
          name: John Doe
        )
      },
      "mixed content": {
        frame: %(
          "@context":
            ex: http://example.org/
          ex:mixed:
            "@embed": "@never"
        ),
        input: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub1
          ex:mixed:
          - "@id": ex:Sub2
          - literal1
        ),
        output: %(
          "@context":
            ex: http://example.org/
          "@id": ex:Sub1
          ex:mixed:
          - "@id": ex:Sub2
          - literal1
        )
      },
      "framed list": {
        frame: %(
          "@context":
            ex: http://example.org/
            list:
              "@id": ex:list
              "@container": "@list"
          list:
          - "@type": ex:Element
        ),
        input: %(
          "@context":
            ex: http://example.org/
            list:
              "@id": ex:list
              "@container": "@list"
          "@id": ex:Sub1
          "@type": ex:Type1
          list:
          - "@id": ex:Sub2
            "@type": ex:Element
          - literal1
        ),
        output: %(
          "@context":
            ex: http://example.org/
            list:
              "@id": ex:list
              "@container": "@list"
          "@id": ex:Sub1
          "@type": ex:Type1
          list:
          - "@id": ex:Sub2
            "@type": ex:Element
          - literal1
        )
      },
      "presentation example": {
        frame: %(
          "@context":
            primaryTopic:
              "@id": http://xmlns.com/foaf/0.1/primaryTopic
              "@type": "@id"
            sameAs:
              "@id": http://www.w3.org/2002/07/owl#sameAs
              "@type": "@id"
          primaryTopic:
            "@type": http://dbpedia.org/class/yago/Buzzwords
            sameAs: {}
        ),
        input: %(
          - "@id": http://en.wikipedia.org/wiki/Linked_Data
            http://xmlns.com/foaf/0.1/primaryTopic:
              "@id": http://dbpedia.org/resource/Linked_Data
          - "@id": http://www4.wiwiss.fu-berlin.de/flickrwrappr/photos/Linked_Data
            http://www.w3.org/2002/07/owl#sameAs:
              "@id": http://dbpedia.org/resource/Linked_Data
          - "@id": http://dbpedia.org/resource/Linked_Data
            "@type": http://dbpedia.org/class/yago/Buzzwords
            http://www.w3.org/2002/07/owl#sameAs:
              "@id": http://rdf.freebase.com/ns/m/02r2kb1
          - "@id": http://mpii.de/yago/resource/Linked_Data
            http://www.w3.org/2002/07/owl#sameAs:
              "@id": http://dbpedia.org/resource/Linked_Data
        ),
        output: %(
          "@context":
            primaryTopic:
              "@id": http://xmlns.com/foaf/0.1/primaryTopic
              "@type": "@id"
            sameAs:
              "@id": http://www.w3.org/2002/07/owl#sameAs
              "@type": "@id"
          "@id": http://en.wikipedia.org/wiki/Linked_Data
          primaryTopic:
            "@id": http://dbpedia.org/resource/Linked_Data
            "@type": http://dbpedia.org/class/yago/Buzzwords
            sameAs: http://rdf.freebase.com/ns/m/02r2kb1
        )
      },
      "library": {
        frame: %(
          "@context":
            dc: http://purl.org/dc/elements/1.1/
            ex: http://example.org/vocab#
            xsd: http://www.w3.org/2001/XMLSchema#
            ex:contains:
              "@type": "@id"
          "@type": ex:Library
          ex:contains: {}
        ),
        input: %(
          "@context":
            dc: http://purl.org/dc/elements/1.1/
            ex: http://example.org/vocab#
            xsd: http://www.w3.org/2001/XMLSchema#
          "@id": http://example.org/library
          "@type": ex:Library
          dc:name: Library
          ex:contains:
            "@id": http://example.org/library/the-republic
            "@type": ex:Book
            dc:creator: Plato
            dc:title: The Republic
            ex:contains:
              "@id": http://example.org/library/the-republic#introduction
              "@type": ex:Chapter
              dc:description: An introductory chapter on The Republic.
              dc:title: The Introduction
        ),
        output: %(
          "@context":
            dc: http://purl.org/dc/elements/1.1/
            ex: http://example.org/vocab#
            xsd: http://www.w3.org/2001/XMLSchema#
            ex:contains:
              "@type": "@id"
          "@id": http://example.org/library
          "@type": ex:Library
          dc:name: Library
          ex:contains:
            "@id": http://example.org/library/the-republic
            "@type": ex:Book
            dc:creator: Plato
            dc:title: The Republic
            ex:contains:
              "@id": http://example.org/library/the-republic#introduction
              "@type": ex:Chapter
              dc:description: An introductory chapter on The Republic.
              dc:title: The Introduction
        )
      }
    }.each do |title, params|
      it title do
        do_frame(params)
      end
    end

    describe "@reverse" do
      {
        "embed matched frames with @reverse": {
          frame: %(
            "@context":
              ex: http://example.org/
            "@type": ex:Type1
            "@reverse":
              ex:includes: {}
          ),
          input: %(
            - "@context":
                ex: http://example.org/
              "@id": ex:Sub1
              "@type": ex:Type1
            - "@context":
                ex: http://example.org/
              "@id": ex:Sub2
              "@type": ex:Type2
              ex:includes:
                "@id": ex:Sub1
          ),
          output: %(
            "@context":
              ex: http://example.org/
            "@id": ex:Sub1
            "@type": ex:Type1
            "@reverse":
              ex:includes:
                "@id": ex:Sub2
                "@type": ex:Type2
                ex:includes:
                  "@id": ex:Sub1
          )
        },
        "embed matched frames with reversed property": {
          frame: %(
            "@context":
              ex: http://example.org/
              excludes:
                "@reverse": ex:includes
            "@type": ex:Type1
            excludes: {}
          ),
          input: %(
            - "@context":
                ex: http://example.org/
              "@id": ex:Sub1
              "@type": ex:Type1
            - "@context":
                ex: http://example.org/
              "@id": ex:Sub2
              "@type": ex:Type2
              ex:includes:
                "@id": ex:Sub1
          ),
          output: %(
            "@context":
              ex: http://example.org/
              excludes:
                "@reverse": ex:includes
            "@id": ex:Sub1
            "@type": ex:Type1
            excludes:
              "@id": ex:Sub2
              "@type": ex:Type2
              ex:includes:
                "@id": ex:Sub1
          )
        },
      }.each do |title, params|
        it title do
          do_frame(params)
        end
      end
    end

    context "omitGraph option" do
      {
        "Defaults to true": {
          input: %(
            - http://example.org/prop:
              - "@value": value
              http://example.org/foo:
              - "@value": bar
          ),
          frame: %(
            "@context":
              "@vocab": http://example.org/
          ),
          output: %(
            "@context":
              "@vocab": http://example.org/
            foo: bar
            prop: value
          )
        },
        "Set with option":  {
          input: %(
            - http://example.org/prop:
              - "@value": value
              http://example.org/foo:
              - "@value": bar
          ),
          frame: %(
            "@context":
              "@vocab": http://example.org/
          ),
          output: %(
            "@context":
              "@vocab": http://example.org/
            "@graph":
            - foo: bar
              prop: value
          ),
          omitGraph: false
        },
      }.each do |title, params|
        it(title) {do_frame(params.merge(pruneBlankNodeIdentifiers: true))}
      end
    end
  end
  def do_frame(params)
    begin
      input, frame, output = params[:input], params[:frame], params[:output]
      input = StringIO.new(input) if input.is_a?(String)
      frame = StringIO.new(frame) if frame.is_a?(String)
      yld = nil
      if params[:write]
        expect{yld = YAML_LD::API.frame(input, frame, logger: logger, **params)}.to write(params[:write]).to(:error)
      else
        expect{yld = YAML_LD::API.frame(input, frame, logger: logger, **params)}.not_to write.to(:error)
      end
      expect(yld).to produce_yamlld(output, logger)
    end
  end
end
