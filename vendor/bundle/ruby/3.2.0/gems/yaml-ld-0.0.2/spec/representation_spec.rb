# coding: utf-8
require_relative 'spec_helper'

describe YAML_LD::Representation do
  describe "load_stream" do
    {
      "Stream": {
        input: %(
          ---
          a
          ...
          ---
          b
          ...
        ),
        expected: %w(a b)
      },
      "String": {
        input: %(a),
        expected: %w(a)
      },
    }.each do |name, params|
      it name do
        input = params[:input]
        ir = YAML_LD::Representation.load_stream(input.unindent.strip)
        expected = params[:expected]
        expect(ir).to be_equivalent_structure expected
      end
    end
  end

  describe "load" do
    {
      "Stream": {
        input: %(
          ---
          a
          ...
          ---
          b
          ...
        ),
        expected: "a"
      },
      "Null": {
        input: %(null),
        expected: nil
      },
      "!!null null": {
        input: %(!!null null),
        expected: nil
      },
      "!<tag:yaml.org,2002:null> null": {
        input: %(!<tag:yaml.org,2002:null> null),
        expected: nil
      },
      "Boolean": {
        input: %(true),
        expected: true
      },
      "!!bool true": {
        input: %(!!bool true),
        expected: true
      },
      "!<tag:yaml.org,2002:bool> true": {
        input: %(!<tag:yaml.org,2002:bool> true),
        expected: true
      },
      "String": {
        input: %(a),
        expected: "a"
      },
      "Tagged !!str String": {
        input: %(!!str string),
        expected: "string"
      },
      "Tagged !<tag:yaml.org,2002:str> String": {
        input: %(!<tag:yaml.org,2002:str> string),
        expected: "string"
      },
      "Integer": {
        input: %(1),
        expected: 1
      },
      "Tagged !!int 1": {
        input: %(!!int 1),
        expected: 1
      },
      "Tagged !<tag:yaml.org,2002:int> 1": {
        input: %(!<tag:yaml.org,2002:int> 1),
        expected: 1
      },
      "Float": {
        input: %(1.0),
        expected: Float(1.0)
      },
      "Tagged !!float -1": {
        input: %(!!float -1),
        expected: Float(-1)
      },
      "Tagged !<tag:yaml.org,2002:float> 2.3e4": {
        input: %(!<tag:yaml.org,2002:float> 2.3e4),
        expected: Float(2.3e4)
      },
      "Tagged !<tag:yaml.org,2002:float> .inf": {
        input: %(!<tag:yaml.org,2002:float> .inf),
        expected: Float::INFINITY
      },
    }.each do |name, params|
      it name do
        input = params[:input]
        ir = YAML_LD::Representation.load(input.unindent.strip)
        expected = params[:expected]
        expect(ir).to be_equivalent_structure expected
      end
    end

    {
      "!<http://www.w3.org/2001/XMLSchema%23integer> 123": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23integer> 123),
        xsd: RDF::Literal("123", datatype: "http://www.w3.org/2001/XMLSchema#integer"),
        plain: 123
      },
      "!<http://www.w3.org/2001/XMLSchema%23decimal> 123.456": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23decimal> 123.456),
        xsd: RDF::Literal("123.456", datatype: "http://www.w3.org/2001/XMLSchema#decimal"),
        plain: 123.456
      },
      "!<http://www.w3.org/2001/XMLSchema%23double> 123.456e78": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23double> 123.456e+78),
        xsd: RDF::Literal("123.456e+78", datatype: "http://www.w3.org/2001/XMLSchema#double"),
        plain: 123.456e+78
      },
      "!<http://www.w3.org/2001/XMLSchema%23boolean> true": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23boolean> true),
        xsd: RDF::Literal("true", datatype: "http://www.w3.org/2001/XMLSchema#boolean"),
        plain: true
      },
      "!<http://www.w3.org/2001/XMLSchema%23date> 2022-08-17": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23date> "2022-08-17"),
        xsd: RDF::Literal("2022-08-17", datatype: "http://www.w3.org/2001/XMLSchema#date"),
        plain: "2022-08-17"
      },
      "!<http://www.w3.org/2001/XMLSchema%23time> 12:00:00.000": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23time> "12:00:00.000"),
        xsd: RDF::Literal("12:00:00.000", datatype: "http://www.w3.org/2001/XMLSchema#time"),
        plain: "12:00:00.000"
      },
      "!<http://www.w3.org/2001/XMLSchema%23dateTime> 2022-08-17T12:00:00.000": {
        input: %(!<http://www.w3.org/2001/XMLSchema%23dateTime> "2022-08-17T12:00:00.000"),
        xsd: RDF::Literal("2022-08-17T12:00:00.000", datatype: "http://www.w3.org/2001/XMLSchema#dateTime"),
        plain: "2022-08-17T12:00:00.000"
      },
    }.each do |name, params|
      it "#{name} with xsd" do
        input = params[:input]
        ir = YAML_LD::Representation.load(input.unindent.strip, extendedYAML: true)
        expected = params[:xsd]
        expect(ir).to be_equivalent_structure expected
      end

      it "#{name} without xsd" do
        input = params[:input]
        ir = YAML_LD::Representation.load(input.unindent.strip, extendedYAML: false)
        expected = params[:plain]
        expect(ir).to be_equivalent_structure expected
      end
    end
  end
end
