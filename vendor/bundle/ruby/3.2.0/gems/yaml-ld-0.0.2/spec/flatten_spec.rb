# coding: utf-8
require_relative 'spec_helper'

describe JSON::LD::API do
  let(:logger) {RDF::Spec.logger}

  describe ".flatten" do
    {
      "single object": {
        input: %(
          "@id": http://example.com
          "@type": http://www.w3.org/2000/01/rdf-schema#Resource
        ),
        output: %(
          - "@id": http://example.com
            "@type":
              - http://www.w3.org/2000/01/rdf-schema#Resource
        )
      },
      "embedded object": {
        input: %(
          "@context":
            foaf: http://xmlns.com/foaf/0.1/
          "@id": http://greggkellogg.net/foaf
          "@type": http://xmlns.com/foaf/0.1/PersonalProfileDocument
          foaf:primaryTopic:
            - "@id": http://greggkellogg.net/foaf#me
              "@type": http://xmlns.com/foaf/0.1/Person
        ),
        output: %(
          - "@id": http://greggkellogg.net/foaf
            "@type":
              - http://xmlns.com/foaf/0.1/PersonalProfileDocument
            http://xmlns.com/foaf/0.1/primaryTopic:
              - "@id": http://greggkellogg.net/foaf#me
          - "@id": http://greggkellogg.net/foaf#me
            "@type":
              - http://xmlns.com/foaf/0.1/Person
        )
      },
      "embedded anon": {
        input: %(
          "@context":
            foaf: http://xmlns.com/foaf/0.1/
          "@id": http://greggkellogg.net/foaf
          "@type": foaf:PersonalProfileDocument
          foaf:primaryTopic:
            "@type": foaf:Person
        ),
        output: %(
          - "@id": _:b0
            "@type":
              - http://xmlns.com/foaf/0.1/Person
          - "@id": http://greggkellogg.net/foaf
            "@type":
              - http://xmlns.com/foaf/0.1/PersonalProfileDocument
            http://xmlns.com/foaf/0.1/primaryTopic:
              - "@id": _:b0
        )
      },
      "reverse properties": {
        input: %(
          - "@id": http://example.com/people/markus
            "@reverse":
              http://xmlns.com/foaf/0.1/knows:
                - "@id": http://example.com/people/dave
                - "@id": http://example.com/people/gregg
            http://xmlns.com/foaf/0.1/name:
              "@value": Markus Lanthaler
        ),
        output: %(
          - "@id": http://example.com/people/dave
            http://xmlns.com/foaf/0.1/knows:
              - "@id": http://example.com/people/markus
          - "@id": http://example.com/people/gregg
            http://xmlns.com/foaf/0.1/knows:
              - "@id": http://example.com/people/markus
          - "@id": http://example.com/people/markus
            http://xmlns.com/foaf/0.1/name:
              - "@value": Markus Lanthaler
        )
      },
      "Simple named graph (Wikidata)": {
        input: %q(
          "@context":
            rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
            ex: http://example.org/
            xsd: http://www.w3.org/2001/XMLSchema#
            ex:locatedIn:
              "@type": "@id"
            ex:hasPopulaton:
              "@type": xsd:integer
            ex:hasReference:
              "@type": "@id"
          "@graph":
          - "@id": http://example.org/ParisFact1
            "@type": rdf:Graph
            "@graph":
              "@id": http://example.org/location/Paris#this
              ex:locatedIn: http://example.org/location/France#this
            ex:hasReference:
            - http://www.britannica.com/
            - http://www.wikipedia.org/
            - http://www.brockhaus.de/
          - "@id": http://example.org/ParisFact2
            "@type": rdf:Graph
            "@graph":
              "@id": http://example.org/location/Paris#this
              ex:hasPopulation: 7000000
            ex:hasReference: http://www.wikipedia.org/
        ),
        output: %q(
          - "@id": http://example.org/ParisFact1
            "@type":
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#Graph
            http://example.org/hasReference:
            - "@id": http://www.britannica.com/
            - "@id": http://www.wikipedia.org/
            - "@id": http://www.brockhaus.de/
            "@graph":
            - "@id": http://example.org/location/Paris#this
              http://example.org/locatedIn:
              - "@id": http://example.org/location/France#this
          - "@id": http://example.org/ParisFact2
            "@type":
            - http://www.w3.org/1999/02/22-rdf-syntax-ns#Graph
            http://example.org/hasReference:
            - "@id": http://www.wikipedia.org/
            "@graph":
            - "@id": http://example.org/location/Paris#this
              http://example.org/hasPopulation:
              - "@value": 7000000
        ),
      },
      "Test Manifest (shortened)": {
        input: %q{
          "@id": ''                                           
          http://example/sequence:                            
            "@list":                                          
            - "@id": "#t0001"                                 
              http://example/name: Keywords cannot be aliased to other keywords
              http://example/input:                           
                "@id": error-expand-0001-in.jsonld            
        },
        output: %q{
          - "@id": ''
            http://example/sequence:
            - "@list":
              - "@id": "#t0001"
          - "@id": "#t0001"
            http://example/input:
            - "@id": error-expand-0001-in.jsonld
            http://example/name:
            - "@value": Keywords cannot be aliased to other keywords
        },
      },
      "@list with embedded object": {
        input: %(
          - http://example.com/foo:
            - "@list":
              - "@id": http://example.com/baz
                http://example.com/bar: buz
        ),
        output: %(
          - "@id": _:b0
            http://example.com/foo:
            - "@list":
              - "@id": http://example.com/baz
          - "@id": http://example.com/baz
            http://example.com/bar:
            - "@value": buz
        )
      },
      "coerced @list containing mixed list values": {
        input: %(
          "@context":
            foo:
              "@id": http://example.com/foo
              "@container": "@list"
          foo:
          - - "@id": http://example/a
              "@type": http://example/Bar
          - "@id": http://example/b
            "@type": http://example/Baz
        ),
        output: %(
          - "@id": _:b0
            http://example.com/foo:
            - "@list":
              - "@list":
                - "@id": http://example/a
              - "@id": http://example/b
          - "@id": http://example/a
            "@type":
            - http://example/Bar
          - "@id": http://example/b
            "@type":
            - http://example/Baz
        )
      },
    }.each do |title, params|
      it(title) {run_flatten(params)}
    end
  end

  def run_flatten(params)
    input, output, context = params[:input], params[:output], params[:context]
    input = StringIO.new(input) if input.is_a?(String)
    context = ::JSON.parse(context) if context.is_a?(String)
    params[:base] ||= nil
    pending params.fetch(:pending, "test implementation") unless input
    if params[:exception]
      expect {YAML_LD::API.flatten(input, context, logger: logger, **params)}.to raise_error(params[:exception])
    else
      yld = nil
      if params[:write]
        expect{yld = YAML_LD::API.flatten(input, context, logger: logger, **params)}.to write(params[:write]).to(:error)
      else
        expect{yld = YAML_LD::API.flatten(input, context, logger: logger, **params)}.not_to write.to(:error)
      end

      expect(yld).to produce_yamlld(output, logger)
    end
  end
end
