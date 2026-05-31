# coding: utf-8
require_relative 'spec_helper'

describe JSON::LD::API do
  let(:logger) {RDF::Spec.logger}

  describe ".expand" do
    {
      "empty doc": {
        input: {},
        output: []
      },
      "@list coercion": {
        input: %(
          "@context":
            foo:
              "@id": http://example.com/foo
              "@container": "@list"
          foo:
          - "@value": bar
        ),
        output: %(
          - http://example.com/foo:
            - "@list":
              - "@value": bar
        )
      },
      "native values in list": {
        input: %(
          http://example.com/foo:
            "@list":
            - 1
            - 2
        ),
        output: %(
          - http://example.com/foo:
            - "@list":
              - "@value": 1
              - "@value": 2
        )
      },
      "@graph": {
        input: %(
          "@context":
            ex: http://example.com/
          "@graph":
          - ex:foo:
              "@value": foo
          - ex:bar:
              "@value": bar
        ),
        output: %(
          - http://example.com/foo:
            - "@value": foo
          - http://example.com/bar:
            - "@value": bar
        )
      },
      "@graph value (expands to array form)": {
        input: %(
          "@context":
            ex: http://example.com/
          ex:p:
            "@id": ex:Sub1
            "@graph":
              ex:q: foo
        ),
        output: %(
          - http://example.com/p:
            - "@id": http://example.com/Sub1
              "@graph":
                - http://example.com/q:
                  - "@value": foo
        )
      },
      "@type with CURIE": {
        input: %(
          "@context":
            ex: http://example.com/
          "@type": ex:type
        ),
        output: %(
          - "@type":
            - http://example.com/type
        )
      },
      "@type with CURIE and muliple values": {
        input: %(
          "@context":
            ex: http://example.com/
          "@type":
          - ex:type1
          - ex:type2
        ),
        output: %(
          - "@type":
            - http://example.com/type1
            - http://example.com/type2
        )
      },
      "@value with false": {
        input: %(
          http://example.com/ex:
            "@value": false
        ),
        output: %(
          - http://example.com/ex:
            - "@value": false
        )
      },
      "compact IRI": {
        input: %(
          "@context":
            ex: http://example.com/
          ex:p:
            "@id": ex:Sub1
        ),
        output: %(
          - http://example.com/p:
            - "@id": http://example.com/Sub1
        )
      },
    }.each_pair do |title, params|
      it(title) {run_expand params}
    end

    context "keyword aliasing" do
      {
        "@id": {
          input: %(
            "@context":
              id: "@id"
            id: ""
            "@type": http://www.w3.org/2000/01/rdf-schema#Resource
          ),
          output: %(
            - "@id": ""
              "@type":
                - http://www.w3.org/2000/01/rdf-schema#Resource
          )
        },
        "@type": {
          input: %(
            "@context":
              type: "@type"
            type: http://www.w3.org/2000/01/rdf-schema#Resource
            http://example.com/foo:
              "@value": bar
              type: http://example.com/baz
          ),
          output: %(
            - "@type":
              - http://www.w3.org/2000/01/rdf-schema#Resource
              http://example.com/foo:
              - "@value": bar
                "@type": http://example.com/baz
          )
        },
        "@language": {
          input: %(
            "@context":
              language: "@language"
            http://example.com/foo:
              "@value": bar
              language: baz
          ),
          output: %(
            - http://example.com/foo:
              - "@value": bar
                "@language": baz
          )
        },
        "@value": {
          input: %(
            "@context":
              literal: "@value"
            http://example.com/foo:
              literal: bar
          ),
          output: %(
            - http://example.com/foo:
              - "@value": bar
          )
        },
        "@list": {
          input: %(
            "@context":
              list: "@list"
            http://example.com/foo:
              list:
              - bar
          ),
          output: %(
            - http://example.com/foo:
              - "@list":
                - "@value": bar
          )
        },
      }.each do |title, params|
        it(title) {run_expand params}
      end
    end

    context "native types" do
      {
        "true": {
          input: %(
            "@context":
              e: http://example.org/vocab#
            e:bool: true
          ),
          output: %(
            - http://example.org/vocab#bool:
              - "@value": true
          )
        },
        "false": {
          input: %(
            "@context":
              e: http://example.org/vocab#
            e:bool: false
          ),
          output: %(
            - http://example.org/vocab#bool:
              - "@value": false
          )
        },
        "double": {
          input: %(
            "@context":
              e: http://example.org/vocab#
            e:double: 1.23
          ),
          output: %(
            - http://example.org/vocab#double:
              - "@value": 1.23
          )
        },
        "double-zero": {
          input: %(
            "@context":
              e: http://example.org/vocab#
            e:double-zero: 0.0e+0
          ),
          output: %(%YAML 1.2\n---
            - http://example.org/vocab#double-zero:
              - "@value": 0.0e+0
          )
        },
        "integer": {
          input: %(
            "@context":
              e: http://example.org/vocab#
            e:integer: 123
          ),
          output: %(
            - http://example.org/vocab#integer:
              - "@value": 123
          )
        },
      }.each do |title, params|
        it(title) {run_expand params}
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
          output: %(
            - http://example.org/vocab#bool:
              - "@value": true
                "@type": "@json"
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
            - http://example.org/vocab#bool:
              - "@value": false
                "@type": "@json"
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
            - http://example.org/vocab#double:
              - "@value": 1.23
                "@type": "@json"
          )
        },
        "double-zero": {
          input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#double
                "@type": "@json"
            e: 0.0e+0
          ),
          output: %(
            - http://example.org/vocab#double:
              - "@value": 0.0e+0
                "@type": "@json"
          )
        },
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
            - http://example.org/vocab#integer:
              - "@value": 123
                "@type": "@json"
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
            - http://example.org/vocab#string:
              - "@value": string
                "@type": "@json"
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
            - http://example.org/vocab#null:
              - "@value": null
                "@type": "@json"
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
            - http://example.org/vocab#object:
              - "@value":
                  foo: bar
                "@type": "@json"
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
            - http://example.org/vocab#array:
              - "@value":
                - foo: bar
                "@type": "@json"
          )
        },
        "Does not expand terms inside json": {
          input: %(
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#array
                "@type": "@json"
            e:
            - e: bar
          ),
          output: %(
            - http://example.org/vocab#array:
              - "@value":
                - e: bar
                "@type": "@json"
          )
        },
        "Already expanded object with aliased keys": {
          input: %(
            "@context":
              "@version": 1.1
              value: "@value"
              type: "@type"
              json: "@json"
            http://example.org/vocab#object:
            - value:
                foo: bar
              type: json
          ),
          output: %(
            - http://example.org/vocab#object:
              - "@value":
                  foo: bar
                "@type": "@json"
          )
        },
      }.each do |title, params|
        it(title) {run_expand params}
      end
    end

    context "@direction" do
      {
        "value with coerced null direction": {
          input: %(
            "@context":
              "@direction": rtl
              ex: http://example.org/vocab#
              ex:ltr:
                "@direction": ltr
              ex:none:
                "@direction":
            ex:rtl: rtl
            ex:ltr: ltr
            ex:none: no direction
          ),
          output: %(
            - http://example.org/vocab#rtl:
              - "@value": rtl
                "@direction": rtl
              http://example.org/vocab#ltr:
              - "@value": ltr
                "@direction": ltr
              http://example.org/vocab#none:
              - "@value": no direction
          )
        }
      }.each_pair do |title, params|
        it(title) {run_expand params}
      end
    end

    context "JSON-LD-star" do
      {
        "node with embedded subject without rdfstar option": {
          input: %(
            "@id":
              "@id": ex:rei
              ex:prop: value
            ex:prop: value2
          ),
          exception: JSON::LD::JsonLdError::InvalidIdValue
        },
        "node with embedded subject with rdfstar option": {
          input: %(
            "@id":
              "@id": ex:rei
              ex:prop: value
            ex:prop: value2
          ),
          output: %(
            - "@id":
                "@id": ex:rei
                ex:prop:
                - "@value": value
              ex:prop:
              - "@value": value2
          ),
          rdfstar: true
        },
        "node object with @annotation property is ignored without rdfstar option": {
          input: %(
            "@id": ex:bob
            ex:knows:
              "@id": ex:fred
              "@annotation":
                ex:certainty: 0.8
          ),
          output: %(
            - "@id": ex:bob
              ex:knows:
              - "@id": ex:fred
          )
        },
        "node object with @annotation property with rdfstar option": {
          input: %(
            "@id": ex:bob
            ex:knows:
              "@id": ex:fred
              "@annotation":
                ex:certainty: 0.8
          ),
          output: %(
            - "@id": ex:bob
              ex:knows:
              - "@id": ex:fred
                "@annotation":
                - ex:certainty:
                  - "@value": 0.8
          ),
          rdfstar: true
        },
      }.each do |title, params|
        it(title) {run_expand params}
      end
    end
  end

  def run_expand(params)
    input, output = params[:input], params[:output]
    params[:base] ||= nil
    input = StringIO.new(input) if input.is_a?(String)
    pending params.fetch(:pending, "test implementation") unless input
    if params[:exception]
      expect {YAML_LD::API.expand(input, **params)}.to raise_error(params[:exception])
    else
      yld = nil
      if params[:write]
        expect{yld = YAML_LD::API.expand(input, logger: logger, **params)}.to write(params[:write]).to(:error)
      else
        expect{yld = YAML_LD::API.expand(input, logger: logger, **params)}.not_to write.to(:error)
      end
      expect(yld).to produce_yamlld(output, logger)

      # Also expect result to produce itself
      expect(output).to produce_yamlld(output, logger)
    end
  end
end
