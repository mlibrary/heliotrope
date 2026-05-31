# coding: utf-8
require_relative 'spec_helper'

describe YAML_LD::API do
  let(:logger) {RDF::Spec.logger}

  context ".toRdf" do
    it "should implement RDF::Enumerable" do
      expect(YAML_LD::API.toRdf({})).to be_a(RDF::Enumerable)
    end

    context "unnamed nodes" do
      {
        "no @id" => [
          %q(
            http://example.com/foo: bar
          ),
          %q([ <http://example.com/foo> "bar"^^xsd:string] .)
        ],
        "@id with _:a" => [
          %q(
          "@id": _:a
          http://example.com/foo: bar
          ),
          %q([ <http://example.com/foo> "bar"^^xsd:string] .)
        ],
        "@id with _:a and reference" => [
          %q(
          "@id": _:a
          http://example.com/foo:
            "@id": _:a
          ),
          %q(_:a <http://example.com/foo> _:a .)
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "nodes with @id" do
      {
        "with IRI" => [
          %q(
          "@id": http://example.com/a
          http://example.com/foo: bar
          ),
          %q(<http://example.com/a> <http://example.com/foo> "bar" .)
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
      
      context "with relative IRIs" do
        {
          "base" => [
            %(
            "@id": ''
            "@type": "#{RDF::RDFS.Resource}"
            ),
            %(<http://example.org/> a <#{RDF::RDFS.Resource}> .)
          ],
          "relative" => [
            %(
            "@id": a/b
            "@type": "#{RDF::RDFS.Resource}"
            ),
            %(<http://example.org/a/b> a <#{RDF::RDFS.Resource}> .)
          ],
          "hash" => [
            %(
            "@id": "#a"
            "@type": "#{RDF::RDFS.Resource}"
            ),
            %(<http://example.org/#a> a <#{RDF::RDFS.Resource}> .)
          ],
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, base: "http://example.org/")).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end
    end

    context "typed nodes" do
      {
        "one type" => [
          %q(
            "@type": "http://example.com/foo"
          ),
          %q([ a <http://example.com/foo> ] .)
        ],
        "two types" => [
          %q(
            "@type": 
            - http://example.com/foo
            - http://example.com/baz
          ),
          %q([ a <http://example.com/foo>, <http://example.com/baz> ] .)
        ],
        "blank node type" => [
          %q(
            "@type": _:foo
          ),
          %q([ a _:foo ] .)
        ]
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "key/value" do
      {
        "string" => [
          %q(
            http://example.com/foo: bar
          ),
          %q([ <http://example.com/foo> "bar"^^xsd:string ] .)
        ],
        "strings" => [
          %q(
            http://example.com/foo:
            - bar
            - baz
          ),
          %q([ <http://example.com/foo> "bar"^^xsd:string, "baz"^^xsd:string ] .)
        ],
        "IRI" => [
          %q(
            http://example.com/foo:
              "@id": http://example.com/bar
          ),
          %q([ <http://example.com/foo> <http://example.com/bar> ] .)
        ],
        "IRIs" => [
          %q(
            http://example.com/foo: 
            - "@id": http://example.com/bar
            - "@id": http://example.com/baz
          ),
          %q([ <http://example.com/foo> <http://example.com/bar>, <http://example.com/baz> ] .)
        ],
      }.each do |title, (yaml, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(yaml)).to be_equivalent_graph(ttl, logger: logger, inputDocument: yaml)
        end
      end
    end

    context "literals" do
      {
        "plain literal" =>
        [
          %q(
          "@id": http://greggkellogg.net/foaf#me
          http://xmlns.com/foaf/0.1/name: Gregg Kellogg
          ),
          %q(<http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/name> "Gregg Kellogg" .)
        ],
        "explicit plain literal" =>
        [
          %q(
          http://xmlns.com/foaf/0.1/name:
            "@value": Gregg Kellogg
          ),
          %q(_:a <http://xmlns.com/foaf/0.1/name> "Gregg Kellogg"^^xsd:string .)
        ],
        "language tagged literal" =>
        [
          %q(
          http://www.w3.org/2000/01/rdf-schema#label:
            "@value": A plain literal with a lang tag.
            "@language": en-us
          ),
          %q(_:a <http://www.w3.org/2000/01/rdf-schema#label> "A plain literal with a lang tag."@en-us .)
        ],
        "I18N literal with language" =>
        [
          %q(
          - "@id": http://greggkellogg.net/foaf#me
            http://xmlns.com/foaf/0.1/knows:
              "@id": http://www.ivan-herman.net/foaf#me
          - "@id": http://www.ivan-herman.net/foaf#me
            http://xmlns.com/foaf/0.1/name:
              "@value": Herman Iván
              "@language": hu
          ),
          %q(
            <http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.net/foaf#me> .
            <http://www.ivan-herman.net/foaf#me> <http://xmlns.com/foaf/0.1/name> "Herman Iv\u00E1n"@hu .
          )
        ],
        "explicit datatyped literal" =>
        [
          %q(
          "@id": http://greggkellogg.net/foaf#me
          http://purl.org/dc/terms/created:
            "@value": '1957-02-27'
            "@type": http://www.w3.org/2001/XMLSchema#date
          ),
          %q(
            <http://greggkellogg.net/foaf#me> <http://purl.org/dc/terms/created> "1957-02-27"^^<http://www.w3.org/2001/XMLSchema#date> .
          )
        ],
      }.each do |title, (yaml, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(yaml)).to be_equivalent_graph(ttl, logger: logger, inputDocument: yaml)
        end
      end

      context "with @type: @json" do
        {
          "true": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#bool
                "@type": "@json"
            e: true
            ),
            output:%(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:bool "true"^^rdf:JSON] .
            )
          },
          "false": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#bool
                "@type": "@json"
            e: false
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:bool "false"^^rdf:JSON] .
            )
          },
          "double": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#double
                "@type": "@json"
            e: 1.23
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:double "1.23"^^rdf:JSON] .
            )
          },
          #"double-zero": {
          #  input: %(
          #  "@context":
          #    "@version": 1.1
          #    e:
          #      "@id": http://example.org/vocab#double
          #      "@type": "@json"
          #  e: 0.0e0
          #  ),
          #  output: %(
          #    @prefix ex: <http://example.org/vocab#> .
          #    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          #    [ex:double "0.0e0"^^rdf:JSON] .
          #  )
          #},
          "integer": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#integer
                "@type": "@json"
            e: 123
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:integer "123"^^rdf:JSON] .
            )
          },
          "string": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#string
                "@type": "@json"
            e: string
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:string "\\"string\\""^^rdf:JSON] .
            )
          },
          "null": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#null
                "@type": "@json"
            e: null
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:null "null"^^rdf:JSON] .
            )
          },
          "object": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#object
                "@type": "@json"
            e:
              foo: bar
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:object """{"foo":"bar"}"""^^rdf:JSON] .
            )
          },
          "array": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#array
                "@type": "@json"
            e:
            - foo: bar
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:array """[{"foo":"bar"}]"""^^rdf:JSON] .
            )
          },
          "c14n-arrays": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#c14n
                "@type": "@json"
            e:
            - 56
            - '1': []
              '10':
              d: true
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """[56,{"1":[],"10":null,"d":true}]"""^^rdf:JSON] .
            )
          },
          "c14n-french": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#c14n
                "@type": "@json"
            e:
              peach: This sorting order
              péché: is wrong according to French
              pêche: but canonicalization MUST
              sin: ignore locale
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """{"peach":"This sorting order","péché":"is wrong according to French","pêche":"but canonicalization MUST","sin":"ignore locale"}"""^^rdf:JSON] .
            )
          },
          "c14n-structures": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#c14n
                "@type": "@json"
            e:
              '1':
                f:
                  f: hi
                  F: 5
                " ": 56
              '10': {}
              '111':
              - e: 'yes'
                E: 'no'
              '': empty
              a: {}
              A: {}
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """{"":"empty","1":{" ":56,"f":{"F":5,"f":"hi"}},"10":{},"111":[{"E":"no","e":"yes"}],"A":{},"a":{}}"""^^rdf:JSON] .
            )
          },
          "c14n-unicode": {
            input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#c14n
                "@type": "@json"
            e:
              Unnormalized Unicode: Å
            ),
            output: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              [ex:c14n """{"Unnormalized Unicode":"Å"}"""^^rdf:JSON] .
            )
          },
        }.each do |title, params|
          it title do
            params[:output] = RDF::Graph.new << RDF::Turtle::Reader.new(params[:output])
            run_to_rdf params
          end
        end
      end
    end

    context "overriding keywords" do
      {
        "'url' for @id, 'a' for @type" => [
          %q(
          "@context":
            url: "@id"
            a: "@type"
            name: http://schema.org/name
          url: http://example.com/about#gregg
          a: http://schema.org/Person
          name: Gregg Kellogg
          ),
          %q(
            <http://example.com/about#gregg> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://schema.org/Person> .
            <http://example.com/about#gregg> <http://schema.org/name> "Gregg Kellogg"^^xsd:string .
          )
        ],
      }.each do |title, (js, ttl)|
        it title do
          ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
          expect(parse(js)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
        end
      end
    end

    context "@direction" do
      context "rdfDirection: null" do
        {
          "no language rtl": [
            %q(
            http://example.org/label:
              "@value": no language
              "@direction": rtl
            ),
            %q(_:a <http://example.org/label> "no language" .)
          ],
          "en-US rtl": [
            %q(
            http://example.org/label:
              "@value": en-US
              "@language": en-US
              "@direction": rtl
            ),
            %q(_:a <http://example.org/label> "en-US"@en-us .)
          ]
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, rdfDirection: nil)).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end

      context "rdfDirection: i18n-datatype" do
        {
          "no language rtl": [
            %q(
            http://example.org/label:
              "@value": no language
              "@direction": rtl
            ),
            %q(_:a <http://example.org/label> "no language"^^<https://www.w3.org/ns/i18n#_rtl> .)
          ],
          "en-US rtl": [
            %q(
            http://example.org/label:
              "@value": en-US
              "@language": en-US
              "@direction": rtl
            ),
            %q(_:a <http://example.org/label> "en-US"^^<https://www.w3.org/ns/i18n#en-us_rtl> .)
          ]
        }.each do |title, (js, ttl)|
          it title do
            ttl = "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> . #{ttl}"
            expect(parse(js, rdfDirection: 'i18n-datatype')).to be_equivalent_graph(ttl, logger: logger, inputDocument: js)
          end
        end
      end
    end
  end

  def parse(input, **options)
    graph = options[:graph] || RDF::Graph.new
    options = {logger: logger, validate: true, canonicalize: false}.merge(options)
    YAML_LD::API.toRdf(StringIO.new(input), rename_bnodes: false, **options) {|st| graph << st}
    graph
  end

  def run_to_rdf(params)
    input, output = params[:input], params[:output]
    graph = params[:graph] || RDF::Graph.new
    input = StringIO.new(input).tap do |d|
      d.define_singleton_method(:content_type) {'application/ld+yaml'}
    end if input.is_a?(String)
    pending params.fetch(:pending, "test implementation") unless input
    if params[:exception]
      expect {YAML_LD::API.toRdf(input, **params)}.to raise_error(params[:exception])
    else
      if params[:write]
        expect{YAML_LD::API.toRdf(input, base: params[:base], logger: logger, rename_bnodes: false, **params) {|st| graph << st}}.to write(params[:write]).to(:error)
      else
        expect{YAML_LD::API.toRdf(input, base: params[:base], logger: logger, rename_bnodes: false, **params) {|st| graph << st}}.not_to write.to(:error)
      end
      expect(graph).to be_equivalent_graph(output, logger: logger, inputDocument: input)
    end
  end
end
