# coding: utf-8
require_relative 'spec_helper'
require 'rdf/spec/writer'

describe YAML_LD::API do
  let(:logger) {RDF::Spec.logger}

  describe ".fromRdf" do
    context "simple tests" do
      it "One subject IRI object" do
        input = %(<http://a/b> <http://a/c> <http://a/d> .)
        expect(serialize(input)).to produce_yamlld(%(
          - "@id": http://a/b
            http://a/c:
            - "@id": http://a/d
        ), logger)
      end

      it "should generate object list" do
        input = %(@prefix : <http://example.com/> . :b :c :d, :e .)
        expect(serialize(input)).
        to produce_yamlld(%(
          - "@id": http://example.com/b
            http://example.com/c:
            - "@id": http://example.com/d
            - "@id": http://example.com/e
        ), logger)
      end

      it "should generate property list" do
        input = %(@prefix : <http://example.com/> . :b :c :d; :e :f .)
        expect(serialize(input)).
        to produce_yamlld(%(
          - "@id": http://example.com/b
            http://example.com/c:
            - "@id": http://example.com/d
            http://example.com/e:
            - "@id": http://example.com/f
        ), logger)
      end

      it "serializes multiple subjects" do
        input = %q(
          @prefix : <http://www.w3.org/2006/03/test-description#> .
          @prefix dc: <http://purl.org/dc/elements/1.1/> .
          <test-cases/0001> a :TestCase .
          <test-cases/0002> a :TestCase .
        )
        expect(serialize(input)).
        to produce_yamlld(%(
          - "@id": test-cases/0001
            "@type":
            - http://www.w3.org/2006/03/test-description#TestCase
          - "@id": test-cases/0002
            "@type":
            - http://www.w3.org/2006/03/test-description#TestCase
        ), logger)
      end
    end

    context "literals" do
      context "coercion" do
        it "typed literal" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b "foo"^^ex:d .)
          expect(serialize(input)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": foo
                "@type": http://example.com/d
          ), logger)
        end

        it "integer" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b 1 .)
          expect(serialize(input, useNativeTypes: true)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": 1
          ), logger)
        end

        it "integer (non-native)" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b 1 .)
          expect(serialize(input, useNativeTypes: false)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": '1'
                "@type": http://www.w3.org/2001/XMLSchema#integer
          ), logger)
        end

        it "boolean" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b true .)
          expect(serialize(input, useNativeTypes: true)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": true
          ), logger)
        end

        it "boolean (non-native)" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b true .)
          expect(serialize(input, useNativeTypes: false)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": 'true'
                "@type": http://www.w3.org/2001/XMLSchema#boolean
          ), logger)
        end

        it "decmal" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b 1.0 .)
          expect(serialize(input, useNativeTypes: true)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": '1.0'
                "@type": http://www.w3.org/2001/XMLSchema#decimal
          ), logger)
        end

        it "double" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b 1.0e0 .)
          expect(serialize(input, useNativeTypes: true)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": 1.0
          ), logger)
        end

        it "double (non-native)" do
          input = %(@prefix ex: <http://example.com/> . ex:a ex:b 1.0e0 .)
          expect(serialize(input, useNativeTypes: false)).to produce_yamlld(%(
            - "@id": http://example.com/a
              http://example.com/b:
              - "@value": 1.0E0
                "@type": http://www.w3.org/2001/XMLSchema#double
          ), logger)
        end
      end

      context "datatyped (non-native)" do
        {
          integer:            1,
          unsignedInteger:    1,
          nonNegativeInteger: 1,
          float:              1,
          nonPositiveInteger: -1,
          negativeInteger:    -1,
        }.each do |t, v|
          it "#{t}" do
            input = %(
              @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
              @prefix ex: <http://example.com/> .
              ex:a ex:b "#{v}"^^xsd:#{t} .
            )
            expect(serialize(input, useNativeTypes: false)).to produce_yamlld(%(
              - "@id": http://example.com/a
                http://example.com/b:
                - "@value": "#{v}"
                  "@type": http://www.w3.org/2001/XMLSchema##{t}
            ), logger)
          end
        end
      end

      it "encodes language literal" do
        input = %(@prefix ex: <http://example.com/> . ex:a ex:b "foo"@en-us .)
        expect(serialize(input)).to produce_yamlld(%(
          - "@id": http://example.com/a
            http://example.com/b:
            - "@value": foo
              "@language": en-us
        ), logger)
      end

      context "with @type: @json" do
        {
          "true": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#bool:
                - "@value": true
                  "@type": "@json"
            ),
            input:%(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:bool "true"^^rdf:JSON .
            )
          },
          "false": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#bool:
                - "@value": false
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:bool "false"^^rdf:JSON .
            )
          },
          "double": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#double:
                - "@value": 1.23
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:double "1.23E0"^^rdf:JSON .
            )
          },
          "double-zero": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#double:
                - "@value": 0
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:double "0.0E0"^^rdf:JSON .
            )
          },
          "integer": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#integer:
                - "@value": 123
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:integer "123"^^rdf:JSON .
            )
          },
          "string": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#string:
                - "@value": string
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:string "\\"string\\""^^rdf:JSON .
            )
          },
          "null": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#null:
                - "@value":
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:null "null"^^rdf:JSON .
            )
          },
          "object": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#object:
                - "@value":
                    foo: bar
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:object """{"foo":"bar"}"""^^rdf:JSON .
            )
          },
          "array": {
            output: %(
              - "@id": http://example.org/vocab#id
                http://example.org/vocab#array:
                - "@value":
                  - foo: bar
                  "@type": "@json"
            ),
            input: %(
              @prefix ex: <http://example.org/vocab#> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              ex:id ex:array """[{"foo":"bar"}]"""^^rdf:JSON .
            )
          },
        }.each do |title, params|
          params[:input] = RDF::Graph.new << RDF::Turtle::Reader.new(params[:input])
          it(title) {do_fromRdf(**params)}
        end
      end
    end

    context "@direction" do
      context "rdfDirection: null" do
        {
          "no language rtl datatype": {
            input: %q(
              <http://example.com/a> <http://example.org/label> "no language"^^<https://www.w3.org/ns/i18n#_rtl> .
            ),
            output: %q(
              - "@id": http://example.com/a
                http://example.org/label:
                - "@value": no language
                  "@type": https://www.w3.org/ns/i18n#_rtl
            ),
          },
          "no language rtl compound-literal": {
            input: %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <http://example.com/a> <http://example.org/label> _:cl1 .

              _:cl1 rdf:value "no language";
                rdf:direction "rtl" .
            ),
            output: %q(
              - "@id": http://example.com/a
                http://example.org/label:
                - "@id": _:cl1
              - "@id": _:cl1
                http://www.w3.org/1999/02/22-rdf-syntax-ns#value:
                - "@value": no language
                http://www.w3.org/1999/02/22-rdf-syntax-ns#direction:
                - "@value": rtl
            ),
          },
          "en-US rtl datatype": {
            input: %q(
              <http://example.com/a> <http://example.org/label> "en-US"^^<https://www.w3.org/ns/i18n#en-us_rtl> .
            ),
            output: %q(
              - "@id": http://example.com/a
                http://example.org/label:
                - "@value": en-US
                  "@type": https://www.w3.org/ns/i18n#en-us_rtl
            ),
          },
          "en-US rtl compound-literal": {
            input: %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <http://example.com/a> <http://example.org/label> _:cl1 .

              _:cl1 rdf:value "en-US";
                rdf:language "en-us";
                rdf:direction "rtl" .
            ),
            output: %q(
              - "@id": http://example.com/a
                http://example.org/label:
                - "@id": _:cl1
              - "@id": _:cl1
                http://www.w3.org/1999/02/22-rdf-syntax-ns#value:
                - "@value": en-US
                http://www.w3.org/1999/02/22-rdf-syntax-ns#language:
                - "@value": en-us
                http://www.w3.org/1999/02/22-rdf-syntax-ns#direction:
                - "@value": rtl
            ),
          }
        }.each_pair do |name, params|
          it name do
            do_fromRdf(params.merge(reader: RDF::Turtle::Reader, rdfDirection: nil))
          end
        end
      end

      context "rdfDirection: i18n-datatype" do
        {
          "no language rtl datatype": {
            input: %q(
              <http://example.com/a> <http://example.org/label> "no language"^^<https://www.w3.org/ns/i18n#_rtl> .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@value": no language
                "@direction": rtl
            ),
          },
          "no language rtl compound-literal": {
            input: %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <http://example.com/a> <http://example.org/label> _:cl1 .

              _:cl1 rdf:value "no language";
                rdf:direction "rtl" .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@id": _:cl1
            - "@id": _:cl1
              http://www.w3.org/1999/02/22-rdf-syntax-ns#value:
              - "@value": no language
              http://www.w3.org/1999/02/22-rdf-syntax-ns#direction:
              - "@value": rtl
            ),
          },
          "en-US rtl datatype": {
            input: %q(
              <http://example.com/a> <http://example.org/label> "en-US"^^<https://www.w3.org/ns/i18n#en-US_rtl> .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@value": en-US
                "@language": en-US
                "@direction": rtl
            ),
          },
          "en-US rtl compound-literal": {
            input: %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <http://example.com/a> <http://example.org/label> _:cl1 .

              _:cl1 rdf:value "en-US";
                rdf:language "en-US";
                rdf:direction "rtl" .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@id": _:cl1
            - "@id": _:cl1
              http://www.w3.org/1999/02/22-rdf-syntax-ns#value:
              - "@value": en-US
              http://www.w3.org/1999/02/22-rdf-syntax-ns#language:
              - "@value": en-US
              http://www.w3.org/1999/02/22-rdf-syntax-ns#direction:
              - "@value": rtl
            ),
          }
        }.each_pair do |name, params|
          it name do
            do_fromRdf(params.merge(reader: RDF::Turtle::Reader, rdfDirection: 'i18n-datatype'))
          end
        end
      end

      context "rdfDirection: compound-literal" do
        {
          "no language rtl datatype": {
            input: %q(
              <http://example.com/a> <http://example.org/label> "no language"^^<https://www.w3.org/ns/i18n#_rtl> .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@value": no language
                "@type": https://www.w3.org/ns/i18n#_rtl
            ),
          },
          "no language rtl compound-literal": {
            input: %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <http://example.com/a> <http://example.org/label> _:cl1 .

              _:cl1 rdf:value "no language";
                rdf:direction "rtl" .
            ),
            output: %q(
              - "@id": http://example.com/a
                http://example.org/label:
                - "@value": no language
                  "@direction": rtl
            ),
          },
          "en-US rtl datatype": {
            input: %q(
              <http://example.com/a> <http://example.org/label> "en-US"^^<https://www.w3.org/ns/i18n#en-us_rtl> .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@value": en-US
                "@type": https://www.w3.org/ns/i18n#en-us_rtl
            ),
          },
          "en-US rtl compound-literal": {
            input: %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <http://example.com/a> <http://example.org/label> _:cl1 .

              _:cl1 rdf:value "en-US";
                rdf:language "en-us";
                rdf:direction "rtl" .
            ),
            output: %q(
            - "@id": http://example.com/a
              http://example.org/label:
              - "@value": en-US
                "@language": en-us
                "@direction": rtl
            ),
          }
        }.each_pair do |name, params|
          it name do
            do_fromRdf(params.merge(reader: RDF::Turtle::Reader, rdfDirection: 'compound-literal'))
          end
        end
      end
    end

    context "RDF-star" do
      {
        "subject-iii": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::URI('http://example/s1'),
              RDF::URI('http://example/p1'),
              RDF::URI('http://example/o1')),
            RDF::URI('http://example/p'),
            RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id": http://example/s1
              http://example/p1:
              - "@id": http://example/o1
            http://example/p:
            - "@id": http://example/o
          )
        },
        "subject-iib": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::URI('http://example/s1'),
              RDF::URI('http://example/p1'),
              RDF::Node.new('o1')),
            RDF::URI('http://example/p'),
            RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id": http://example/s1
              http://example/p1:
              - "@id": _:o1
            http://example/p:
            - "@id": http://example/o
          )
        },
        "subject-iil": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::URI('http://example/s1'),
              RDF::URI('http://example/p1'),
              RDF::Literal('o1')),
            RDF::URI('http://example/p'),
            RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id": http://example/s1
              http://example/p1:
              - "@value": o1
            http://example/p:
            - "@id": http://example/o
          )
        },
        "subject-bii": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::Node('s1'),
              RDF::URI('http://example/p1'),
              RDF::URI('http://example/o1')),
            RDF::URI('http://example/p'),
            RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id": _:s1
              http://example/p1:
              - "@id": http://example/o1
            http://example/p:
            - "@id": http://example/o
          )
        },
        "subject-bib": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::Node('s1'),
              RDF::URI('http://example/p1'),
              RDF::Node.new('o1')),
            RDF::URI('http://example/p'), RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id": _:s1
              http://example/p1:
              - "@id": _:o1
            http://example/p:
            - "@id": http://example/o
          )
        },
        "subject-bil": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::Node('s1'),
              RDF::URI('http://example/p1'),
              RDF::Literal('o1')),
            RDF::URI('http://example/p'),
            RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id": _:s1
              http://example/p1:
              - "@value": o1
            http://example/p:
            - "@id": http://example/o
          )
        },
        "object-iii":  {
          input: RDF::Statement(
            RDF::URI('http://example/s'),
            RDF::URI('http://example/p'),
            RDF::Statement(
              RDF::URI('http://example/s1'),
              RDF::URI('http://example/p1'),
              RDF::URI('http://example/o1'))),
          output: %(
          - "@id": http://example/s
            http://example/p:
            - "@id":
                "@id": http://example/s1
                http://example/p1:
                - "@id": http://example/o1
          )
        },
        "object-iib":  {
          input: RDF::Statement(
            RDF::URI('http://example/s'),
            RDF::URI('http://example/p'),
            RDF::Statement(
              RDF::URI('http://example/s1'),
              RDF::URI('http://example/p1'),
              RDF::Node.new('o1'))),
          output: %(
          - "@id": http://example/s
            http://example/p:
            - "@id":
                "@id": http://example/s1
                http://example/p1:
                - "@id": _:o1
          )
        },
        "object-iil":  {
          input: RDF::Statement(
            RDF::URI('http://example/s'),
            RDF::URI('http://example/p'),
            RDF::Statement(
              RDF::URI('http://example/s1'),
              RDF::URI('http://example/p1'),
              RDF::Literal('o1'))),
          output: %(
          - "@id": http://example/s
            http://example/p:
            - "@id":
                "@id": http://example/s1
                http://example/p1:
                - "@value": o1
          )
        },
        "recursive-subject": {
          input: RDF::Statement(
            RDF::Statement(
              RDF::Statement(
                RDF::URI('http://example/s2'),
                RDF::URI('http://example/p2'),
                RDF::URI('http://example/o2')),
              RDF::URI('http://example/p1'),
              RDF::URI('http://example/o1')),
            RDF::URI('http://example/p'),
            RDF::URI('http://example/o')),
          output: %(
          - "@id":
              "@id":
                "@id": http://example/s2
                http://example/p2:
                - "@id": http://example/o2
              http://example/p1:
              - "@id": http://example/o1
            http://example/p:
            - "@id": http://example/o
          )
        },
      }.each do |name, params|
        it name do
          graph = RDF::Graph.new {|g| g << params[:input]}
          do_fromRdf(params.merge(input: graph, prefixes: {ex: 'http://example/'}))
        end
      end
    end
  end

  def parse(input, **options)
    reader = options[:reader] || RDF::TriG::Reader
    reader.new(input, **options, &:each_statement).to_a.extend(RDF::Enumerable)
  end

  # Serialize ntstr to a string and compare against regexps
  def serialize(ntstr, **options)
    logger.info ntstr if ntstr.is_a?(String)
    g = ntstr.is_a?(String) ? parse(ntstr, **options) : ntstr
    logger.info g.dump(:trig)
    statements = g.each_statement.to_a
    YAML_LD::API.fromRdf(statements, logger: logger, **options)
  end

  def do_fromRdf(params)
    begin
      input, output = params[:input], params[:output]
      jld = nil
      if params[:write]
        expect{jld = serialize(input, **params)}.to write(params[:write]).to(:error)
      else
        expect{jld = serialize(input, **params)}.not_to write.to(:error)
      end
      expect(jld).to produce_yamlld(output, logger)
    rescue JSON::LD::JsonLdError => e
      fail("#{e.class}: #{e.message}\n" +
        "#{logger}\n" +
        "Backtrace:\n#{e.backtrace.join("\n")}")
    end
  end
end
