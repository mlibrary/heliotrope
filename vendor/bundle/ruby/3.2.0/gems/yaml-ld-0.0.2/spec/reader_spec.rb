# coding: utf-8
require_relative 'spec_helper'
require 'rdf/spec/reader'

describe YAML_LD::Reader do
  let!(:doap) {File.expand_path("../../etc/doap.yamlld", __FILE__)}
  let!(:doap_nt) {File.expand_path("../../etc/doap.nt", __FILE__)}
  let!(:doap_count) {File.open(doap_nt).each_line.to_a.length}
  let(:logger) {RDF::Spec.logger}

  after(:each) {|example| puts logger.to_s if example.exception}

  it_behaves_like 'an RDF::Reader' do
    let(:reader_input) {File.read(doap)}
    let(:reader) {YAML_LD::Reader.new(reader_input)}
    let(:reader_count) {doap_count}
  end

  describe ".for" do
    formats = [
      :yamlld,
      "etc/doap.yamlld",
      {file_name:      'etc/doap.yamlld'},
      {file_extension: 'yamlld'},
      {content_type:   'application/ld+yaml'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Reader.for(arg)).to eq YAML_LD::Reader
      end
    end
  end

  context "when validating" do
    it "detects invalid YAML" do
      yaml = %(
      ---
      "@context":
        dc: http://purl.org/dc/terms/
      - foo
      )
      expect do |b|
        described_class.new(StringIO.new(yaml), validate: true, logger: false).each_statement(&b)
      end.to raise_error(RDF::ReaderError)
    end
  end

  context :interface do
    {
      plain: %q(
        "@context":
          foaf:
            http://xmlns.com/foaf/0.1/
        "@id":
          _:bnode1
        "@type":
          foaf:Person
        "foaf:homepage":
          http://example.com/bob/
        "foaf:name":
          Bob
      ),
      leading_comment: %q(---
        # A comment before content
        "@context":
          foaf:
            http://xmlns.com/foaf/0.1/
        "@id":
          _:bnode1
        "@type":
          foaf:Person
        "foaf:homepage":
          http://example.com/bob/
        "foaf:name":
          Bob
      ),
      yaml_version: %(%YAML 1.2\n---
        # A comment before content
        "@context":
          foaf:
            http://xmlns.com/foaf/0.1/
        "@id":
          _:bnode1
        "@type":
          foaf:Person
        "foaf:homepage":
          http://example.com/bob/
        "foaf:name":
          Bob
      ),
    }.each do |variant, src|
      context variant do
        subject {src}

        describe "#initialize" do
          it "yields reader given string" do
            inner = double("inner")
            expect(inner).to receive(:called).with(YAML_LD::Reader)
            YAML_LD::Reader.new(subject) do |reader|
              inner.called(reader.class)
            end
          end

          it "yields reader given IO" do
            inner = double("inner")
            expect(inner).to receive(:called).with(YAML_LD::Reader)
            YAML_LD::Reader.new(StringIO.new(subject)) do |reader|
              inner.called(reader.class)
            end
          end

          it "returns reader" do
            expect(YAML_LD::Reader.new(subject)).to be_a(YAML_LD::Reader)
          end
        end

        describe "#each_statement" do
          it "yields statements" do
            inner = double("inner")
            expect(inner).to receive(:called).with(RDF::Statement).exactly(3)
            YAML_LD::Reader.new(subject).each_statement do |statement|
              inner.called(statement.class)
            end
          end
        end

        describe "#each_triple" do
          it "yields statements" do
            inner = double("inner")
            expect(inner).to receive(:called).exactly(3)
            YAML_LD::Reader.new(subject).each_triple do |subject, predicate, object|
              inner.called(subject.class, predicate.class, object.class)
            end
          end
        end
      end
    end
  end
end
