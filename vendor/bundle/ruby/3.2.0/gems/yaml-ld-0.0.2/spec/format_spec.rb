# coding: utf-8
require_relative 'spec_helper'
require 'rdf/spec/format'

describe YAML_LD::Format do
  it_behaves_like 'an RDF::Format' do
    let(:format_class) {YAML_LD::Format}
  end

  describe ".for" do
    [
      :yamlld,
      "etc/doap.yamlld",
      {file_name:      'etc/doap.yamlld'},
      {file_extension: 'yamlld'},
      {content_type:   'application/ld+yaml'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Format.for(arg)).to eq described_class
      end
    end

    {
      yamlld:   %(---
        "@context": "foo"
      ),
      context:  %(---
        "@context": {
      ),
      id:       %(---
        "@id": "foo"
      ),
      type:       %(---
        "@type": "foo"
      ),
    }.each do |sym, str|
      it "detects #{sym}" do
        expect(described_class.for {str}).to eq described_class
      end
    end

    it "should discover 'yamlld'" do
      expect(RDF::Format.for(:yamlld).reader).to eq YAML_LD::Reader
    end
  end

  describe "#to_sym" do
    specify {expect(described_class.to_sym).to eq :yamlld}
  end

  describe "#to_uri" do
    specify {expect(described_class.to_uri).to eq RDF::URI('http://www.w3.org/ns/formats/YAML-LD')}
  end

  describe ".cli_commands", skip: Gem.win_platform? do
    require 'rdf/cli'
    let(:ttl) {File.expand_path("../test-files/test-1-rdf.ttl", __FILE__)}
    let(:yaml) {File.expand_path("../test-files/test-1-input.yamlld", __FILE__)}
    let(:json) {File.expand_path("../test-files/test-1-compacted.jsonld", __FILE__)}
    let(:context) {File.expand_path("../test-files/test-1-context.jsonld", __FILE__)}

    describe "#expand" do
      it "expands RDF" do
        expect {RDF::CLI.exec(["expand", ttl], format: :ttl, output_format: :yamlld)}.to write.to(:output)
      end
      it "expands JSON" do
        expect {RDF::CLI.exec(["expand", json], format: :jsonld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
      it "expands YAML" do
        expect {RDF::CLI.exec(["expand", yaml], format: :yamlld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
    end

    describe "#compact" do
      it "compacts RDF" do
        expect {RDF::CLI.exec(["compact", ttl], context: context, format: :ttl, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
      it "compacts JSON" do
        expect {RDF::CLI.exec(["compact", json], context: context, format: :jsonld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
      it "compacts YAML" do
        expect {RDF::CLI.exec(["compact", yaml], context: context, format: :yamlld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
    end

    describe "#flatten" do
      it "flattens RDF" do
        expect {RDF::CLI.exec(["flatten", ttl], context: context, format: :ttl, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
      it "flattens JSON" do
        expect {RDF::CLI.exec(["flatten", json], context: context, format: :jsonld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
      it "flattens YAML" do
        expect {RDF::CLI.exec(["flatten", yaml], context: context, format: :yamlld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
    end

    describe "#frame" do
      it "frames RDF" do
        expect {RDF::CLI.exec(["frame", ttl], frame: context, format: :ttl, output_format: :yamlld)}.to write.to(:output)
      end
      it "frames JSON" do
        expect {RDF::CLI.exec(["frame", json], frame: context, format: :jsonld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
      it "frames YAML" do
        expect {RDF::CLI.exec(["frame", yaml], frame: context, format: :yamlld, output_format: :yamlld, validate: false)}.to write.to(:output)
      end
    end
  end
end
