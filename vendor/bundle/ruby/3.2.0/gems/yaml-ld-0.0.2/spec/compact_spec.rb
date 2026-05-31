# coding: utf-8
require_relative 'spec_helper'

describe YAML_LD::API do
  let(:logger) {RDF::Spec.logger}

  describe ".compact" do
    {
      "prefix" => {
        input: %(---
          "@id": http://example.com/a
          http://example.com/b:
            "@id": http://example.com/c
        ),
        context: %({"ex": "http://example.com/"}),
        output: %(%YAML 1.2\n---
          "@context":
            ex: http://example.com/
          "@id": ex:a
          ex:b:
            "@id": ex:c
        )
      },
      "term" => {
        input: %(---
          "@id": http://example.com/a
          http://example.com/b:
            "@id": http://example.com/c
        ),
        context: %({"b": "http://example.com/b"}),
        output: %(%YAML 1.2\n---
          "@context":
            b: http://example.com/b
          "@id": http://example.com/a
          b:
            "@id": http://example.com/c
        )
      },
      "integer value" => {
        input: %(---
          "@id": http://example.com/a
          http://example.com/b:
            "@value": 1
        ),
        context: %({"b": "http://example.com/b"}),
        output: %(%YAML 1.2\n---
          "@context":
            b: http://example.com/b
          "@id": http://example.com/a
          b: 1
        )
      },
      "boolean value" => {
        input: %(---
          "@id": http://example.com/a
          http://example.com/b:
            "@value": true
        ),
        context: %({"b": "http://example.com/b"}),
        output: %(%YAML 1.2\n---
          "@context":
            b: http://example.com/b
          "@id": http://example.com/a
          b: true
        )
      },
      "@id" => {
        input: %(---
          "@id": http://example.org/test#example
        ),
        context: {},
        output: %{%YAML 1.2
          --- {}
        }
      },
      "@id coercion" => {
        input: %({
          "@id": "http://example.com/a",
          "http://example.com/b": {"@id": "http://example.com/c"}
        }),
        context: %({"b": {"@id": "http://example.com/b", "@type": "@id"}}),
        output: %(%YAML 1.2\n---
          "@context":
            b:
              "@id": http://example.com/b
              "@type": "@id"
          "@id": http://example.com/a
          b: http://example.com/c
        )
      },
      "xsd:date coercion" => {
        input: %(---
          http://example.com/b:
            "@value": '2012-01-04'
            "@type": http://www.w3.org/2001/XMLSchema#date
        ),
        context: %({
          "xsd": "http://www.w3.org/2001/XMLSchema#",
          "b": {"@id": "http://example.com/b", "@type": "xsd:date"}
        }),
        output: %(%YAML 1.2\n---
          "@context":
            xsd: http://www.w3.org/2001/XMLSchema#
            b:
              "@id": http://example.com/b
              "@type": xsd:date
          b: '2012-01-04'
        )
      },
      "default language" => {
        input: %(---
          http://example.com/term:
          - v5
          - "@value": plain literal
        ),
        context: %({
          "term5": {"@id": "http://example.com/term", "@language": null},
          "@language": "de"
        }),
        output: %(%YAML 1.2\n---
          "@context":
            term5:
              "@id": http://example.com/term
              "@language":
            "@language": de
          term5:
          - v5
          - plain literal
        )
      },
      "default direction" => {
        input: %(---
          http://example.com/term:
          - v5
          - "@value": plain literal
        ),
        context: %({
          "term5": {"@id": "http://example.com/term", "@direction": null},
          "@direction": "ltr"
        }),
        output: %(%YAML 1.2\n---
          "@context":
            term5:
              "@id": http://example.com/term
              "@direction":
            "@direction": ltr
          term5:
          - v5
          - plain literal
        )
      },
    }.each_pair do |title, params|
      it(title) {run_compact(params)}
    end

    context "with @type: @json" do
      {
        "true": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#bool
                "@type": "@json"
            e: true
          ),
          input:%(
            - http://example.org/vocab#bool:
              - "@value": true
                "@type": "@json"
          ),
        },
        "false": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#bool
                "@type": "@json"
            e: false
          ),
          input:%(
            - http://example.org/vocab#bool:
              - "@value": false
                "@type": "@json"
          )
        },
        "double": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#double
                "@type": "@json"
            e: 1.23
          ),
          input:%(
            - http://example.org/vocab#double:
              - "@value": 1.23
                "@type": "@json"
          )
        },
        "double-zero": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#double
                "@type": "@json"
            e: 0.0e0
          ),
          input:%(
            - http://example.org/vocab#double:
              - "@value": 0.0e0
                "@type": "@json"
          )
        },
        "integer": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#integer
                "@type": "@json"
            e: 123
          ),
          input:%(
            - http://example.org/vocab#integer:
              - "@value": 123
                "@type": "@json"
          )
        },
        "string": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#string
                "@type": "@json"
            e: string
          ),
          input:%(
            - http://example.org/vocab#string:
              - "@value": string
                "@type": "@json"
          )
        },
        "null": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#null
                "@type": "@json"
            e:
          ),
          input:%(
            - http://example.org/vocab#null:
              - "@value": null
                "@type": "@json"
          )
        },
        "object": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#object
                "@type": "@json"
            e:
              foo: bar
          ),
          input:%(
            - http://example.org/vocab#object:
              - "@value":
                  foo: bar
                "@type": "@json"
          )
        },
        "array": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              e:
                "@id": http://example.org/vocab#object
                "@type": "@json"
            e:
            - foo
            - bar
          ),
          input:%(
            - http://example.org/vocab#object:
              - "@value": [foo, bar]
                "@type": "@json"
          )
        },
        "Already expanded object": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
            http://example.org/vocab#object:
              "@value":
                foo: bar
              "@type": "@json"
          ),
          input:%(
            - http://example.org/vocab#object:
              - "@value": {foo: bar}
                "@type": "@json"
          )
        },
        "Already expanded object with aliased keys": {
          output: %(%YAML 1.2\n---
            "@context":
              "@version": 1.1
              value: "@value"
              type: "@type"
              json: "@json"
            http://example.org/vocab#object:
              value:
                foo: bar
              type: json
          ),
          input:%(
            - http://example.org/vocab#object:
              - "@value": {foo: bar}
                "@type": "@json"
          )
        },
      }.each do |title, params|
        it(title) {run_compact(**params)}
      end
    end
  end

  def run_compact(params)
    input, output, context = params[:input], params[:output], params[:context]
    params[:base] ||= nil
    context ||= output  # Since it will have the context
    input = StringIO.new(input.unindent) if input.is_a?(String)
    input.define_singleton_method(:content_type) {'application/ld+yaml'}
    context = Psych.safe_load(context.unindent, aliases: true) if context.is_a?(String)
    context = context['@context'] if context.key?('@context')
    pending params.fetch(:pending, "test implementation") unless input
    if params[:exception]
      expect {YAML_LD::API.compact(input, context, logger: logger, **params)}.to raise_error(params[:exception])
    else
      yaml = nil
      if params[:write]
        expect{yaml = YAML_LD::API.compact(input, context, logger: logger, **params)}.to write(params[:write]).to(:error)
      else
        expect{yaml = YAML_LD::API.compact(input, context, logger: logger, **params)}.not_to write.to(:error)
      end

      expect(yaml.strip).to eq output.unindent.strip
    end
  end
end
