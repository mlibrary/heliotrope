# coding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/reader'

describe RDF::Tabular::Reader do
  let(:logger) {RDF::Spec.logger}
  let!(:doap) {File.expand_path("../../etc/doap.csv", __FILE__)}
  let!(:doap_count) {9}

  before(:each) do
    WebMock.stub_request(:any, %r(.*example.org.*)).
      to_return(lambda {|request|
        file = request.uri.to_s.split('/').last
        content_type = case file
        when /\.json/ then 'application/json'
        when /\.csv/  then 'text/csv'
        else 'text/plain'
        end

        path = File.expand_path("../data/#{file}", __FILE__)
        if File.exist?(path)
          {
            body: File.read(path),
            status: 200,
            headers: {'Content-Type' => content_type}
          }
        else
          {status: 401}
        end
      })
  end
  after(:each) {|example| puts logger.to_s if example.exception}
  
  # @see lib/rdf/spec/reader.rb in rdf-spec
  # two failures specific to the way @input is handled in rdf-tabular make this a problem
  #it_behaves_like 'an RDF::Reader' do
  #  let(:reader_input) {doap}
  #  let(:reader) {RDF::Tabular::Reader.new(StringIO.new(""))}
  #  let(:reader_count) {doap_count}
  #end

  it "should be discoverable" do
    readers = [
      RDF::Reader.for(:tabular),
      RDF::Reader.for("etc/doap.csv"),
      RDF::Reader.for(file_name:      "etc/doap.csv"),
      RDF::Reader.for(file_extension: "csv"),
      RDF::Reader.for(content_type:   "text/csv"),
    ]
    readers.each { |reader| expect(reader).to eq RDF::Tabular::Reader }
  end

  context "HTTP Headers" do
    before(:each) {
      allow_any_instance_of(RDF::Tabular::Dialect).to receive(:embedded_metadata).and_return(RDF::Tabular::Table.new({}, logger: false))
      allow_any_instance_of(RDF::Tabular::Metadata).to receive(:each_row).and_yield(RDF::Statement.new)
    }
    it "sets delimiter to TAB in dialect given text/tsv" do
      input = double("input", content_type: "text/tsv", headers: {content_type: "text/tsv"}, charset: nil)
      expect_any_instance_of(RDF::Tabular::Dialect).to receive(:separator=).with("\t")
      RDF::Tabular::Reader.new(input, logger: false) {|r| r.each_statement {}}
    end
    it "sets header to false in dialect given header=absent" do
      input = double("input", content_type: "text/csv", headers: {content_type: "text/csv;header=absent"}, charset: nil)
      expect_any_instance_of(RDF::Tabular::Dialect).to receive(:header=).with(false)
      RDF::Tabular::Reader.new(input, logger: false) {|r| r.each_statement {}}
    end
    it "sets encoding to ISO-8859-4 in dialect given charset=ISO-8859-4" do
      input = double("input", content_type: "text/csv", headers: {content_type: "text/csv;charset=ISO-8859-4"}, charset: "ISO-8859-4")
      expect_any_instance_of(RDF::Tabular::Dialect).to receive(:encoding=).with("ISO-8859-4")
      RDF::Tabular::Reader.new(input, logger: false) {|r| r.each_statement {}}
    end
    it "sets lang to de in metadata given Content-Language=de", pending: "affecting some RSpec matcher" do
      input = double("input", content_type: "text/csv", headers: {content_language: "de"}, charset: nil)
      expect_any_instance_of(RDF::Tabular::Metadata).to receive(:lang=).with("de")
      RDF::Tabular::Reader.new(input, logger: false) {|r| r.each_statement {}}
    end
    it "does not set lang with two languages in metadata given Content-Language=de, en" do
      input = double("input", content_type: "text/csv", headers: {content_language: "de, en"}, charset: nil)
      expect_any_instance_of(RDF::Tabular::Metadata).not_to receive(:lang=)
      RDF::Tabular::Reader.new(input, logger: false) {|r| r.each_statement {}}
    end
  end

  context "non-file input" do
    let(:expected) {
      JSON.parse(%({
        "tables": [
          {
            "url": "",
            "row": [
              {
                "url": "#row=2",
                "rownum": 1,
                "describes": [
                  {
                    "country": "AD",
                    "name": "Andorra"
                  }
                ]
              },
              {
                "url": "#row=3",
                "rownum": 2,
                "describes": [
                  {
                    "country": "AF",
                    "name": "Afghanistan"
                  }
                ]
              },
              {
                "url": "#row=4",
                "rownum": 3,
                "describes": [
                  {
                    "country": "AI",
                    "name": "Anguilla"
                  }
                ]
              },
              {
                "url": "#row=5",
                "rownum": 4,
                "describes": [
                  {
                    "country": "AL",
                    "name": "Albania"
                  }
                ]
              }
            ]
          }
        ]
      }))
    }

    {
      StringIO: StringIO.new(File.read(File.expand_path("../data/country-codes-and-names.csv", __FILE__))),
      ArrayOfArrayOfString: CSV.new(File.open(File.expand_path("../data/country-codes-and-names.csv", __FILE__))).to_a,
      String: File.read(File.expand_path("../data/country-codes-and-names.csv", __FILE__)),
    }.each do |name, input|
      it name do
        RDF::Tabular::Reader.new(input, noProv: true, logger: logger) do |reader|
          expect(JSON.parse(reader.to_json)).to produce(expected,
            logger: logger,
            result: expected,
            noProv: true,
            metadata: reader.metadata
          )
        end
      end
    end
  end

  context "Test Files" do
    test_files = {
      "tree-ops.csv" => "tree-ops-standard.ttl",
      "tree-ops.csv-metadata.json" => "tree-ops-standard.ttl",
      "tree-ops-ext.json" => "tree-ops-ext-standard.ttl",
      "tree-ops-virtual.json" => "tree-ops-virtual-standard.ttl",
      "country-codes-and-names.csv" => "country-codes-and-names-standard.ttl",
      "countries.json" => "countries-standard.ttl",
      "countries.csv" => "countries.csv-standard.ttl",
      "countries.html" => "countries_html-standard.ttl",
      "countries_embed.html" => "countries_embed-standard.ttl",
      "roles.json" => "roles-standard.ttl",
    }
    context "#each_statement" do
      test_files.each do |csv, ttl|
        context csv do
          let(:about) {RDF::URI("http://example.org").join(csv)}
          let(:input) {File.expand_path("../data/#{csv}", __FILE__)}

          it "standard mode" do
            expected = File.expand_path("../data/#{ttl}", __FILE__)
            RDF::Reader.open(input, format: :tabular, base_uri: about, noProv: true, logger: logger) do |reader|
              graph = RDF::Graph.new << reader
              graph2 = RDF::Graph.load(expected, base_uri: about)
              expect(graph).to be_equivalent_graph(graph2,
                                                   logger: logger,
                                                   id: about,
                                                   action: about,
                                                   result: expected,
                                                   metadata: reader.metadata)
            end
          end

          it "minimal mode" do
            ttl = ttl.sub("standard", "minimal")
            expected = File.expand_path("../data/#{ttl}", __FILE__)
            RDF::Reader.open(input, format: :tabular, base_uri: about, minimal: true, logger: logger) do |reader|
              graph = RDF::Graph.new << reader
              graph2 = RDF::Graph.load(expected, base_uri: about)
              expect(graph).to be_equivalent_graph(graph2,
                                                   logger: logger,
                                                   id: about,
                                                   action: about,
                                                   result: expected,
                                                   metadata: reader.metadata)
            end
          end
        end
      end
    end

    describe "#to_json" do
      test_files.each do |csv, ttl|
        context csv do
          let(:about) {RDF::URI("http://example.org").join(csv)}
          let(:input) {File.expand_path("../data/#{csv}", __FILE__)}
          it "standard mode" do
            json = ttl.sub("-standard.ttl", "-standard.json")
            expected = File.expand_path("../data/#{json}", __FILE__)

            RDF::Reader.open(input, format: :tabular, base_uri: about, noProv: true, logger: logger) do |reader|
              expect(JSON.parse(reader.to_json)).to produce(
                JSON.parse(File.read(expected)),
                logger: logger,
                id: about,
                action: about,
                result: expected,
                noProv: true,
                metadata: reader.metadata
              )
            end
          end

          it "minimal mode" do
            json = ttl.sub("-standard.ttl", "-minimal.json")
            expected = File.expand_path("../data/#{json}", __FILE__)

            RDF::Reader.open(input, format: :tabular, base_uri: about, minimal: true, logger: logger) do |reader|
              expect(JSON.parse(reader.to_json)).to produce(
                JSON.parse(File.read(expected)),
                logger: logger,
                id: about,
                action: about,
                result: expected,
                minimal: true,
                metadata: reader.metadata
              )
            end
          end

          it "ADT mode", unless: true do
            json = ttl.sub("-standard.ttl", "-atd.json")
            expected = File.expand_path("../data/#{json}", __FILE__)

            RDF::Reader.open(input, format: :tabular, base_uri: about, noProv: true, logger: logger) do |reader|
              expect(JSON.parse(reader.to_json(atd: true))).to produce(
                JSON.parse(File.read(expected)),
                logger: logger,
                id: about,
                action: about,
                result: expected,
                noProv: true,
                metadata: reader.metadata
              )
            end
          end
        end
      end
    end
  end

  context "Primary Keys" do
    it "has expected primary keys" do
      RDF::Reader.open("http://example.org/countries.json", format: :tabular, validate: true) do |reader|
        reader.each_statement {}
        pks = reader.metadata.tables.first.object[:rows].map(&:primaryKey)

        # Each entry is an array of cells
        expect(pks.map {|r| r.map(&:value).join(",")}).to eql %w(AD AE AF)
      end
    end

    it "errors on duplicate primary keys" do
      RDF::Reader.open("http://example.org/test232-metadata.json", format: :tabular, validate: true, logger: logger) do |reader|
        expect {reader.validate!}.to raise_error(RDF::Tabular::Error)

        pks = reader.metadata.tables.first.object[:rows].map(&:primaryKey)

        # Each entry is an array of cells
        expect(pks.map {|r| r.map(&:value).join(",")}).to eql %w(1 1)

        expect(logger.to_s).to include "Table http://example.org/test232.csv has duplicate primary key 1"
      end
    end
  end

  context "Foreign Keys" do
    let(:path) {File.expand_path("../data/countries.json", __FILE__)}
    it "validates consistent foreign keys" do
      RDF::Reader.open(path, format: :tabular, validate: true, warnings: []) do |reader|
        reader.each_statement {}
        expect(reader.options[:warnings]).to be_empty
      end
    end
  end

  context "Provenance" do
    {
      "country-codes-and-names.csv" => %(
        PREFIX csvw: <http://www.w3.org/ns/csvw#>
        PREFIX prov: <http://www.w3.org/ns/prov#>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        ASK WHERE {
          [ prov:wasGeneratedBy [
              a prov:Activity;
              prov:wasAssociatedWith <https://rubygems.org/gems/rdf-tabular>;
              prov:startedAtTime ?start;
              prov:endedAtTime ?end;
              prov:qualifiedUsage [
                a prov:Usage ;
                prov:entity <http://example.org/country-codes-and-names.csv> ;
                prov:hadRole csvw:csvEncodedTabularData
              ];
            ]
          ]
          FILTER (
            DATATYPE(?start) = xsd:dateTime &&
            DATATYPE(?end) = xsd:dateTime
          )
        }
      ),
      "countries.json" => %(
        PREFIX csvw: <http://www.w3.org/ns/csvw#>
        PREFIX prov: <http://www.w3.org/ns/prov#>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        ASK WHERE {
          [ prov:wasGeneratedBy [
              a prov:Activity;
              prov:wasAssociatedWith <https://rubygems.org/gems/rdf-tabular>;
              prov:startedAtTime ?start;
              prov:endedAtTime ?end;
              prov:qualifiedUsage [
                a prov:Usage ;
                prov:entity <http://example.org/countries.csv>, <http://example.org/country_slice.csv>;
                prov:hadRole csvw:csvEncodedTabularData
              ], [
                a prov:Usage ;
                prov:entity <http://example.org/countries.json> ;
                prov:hadRole csvw:tabularMetadata
              ];
            ]
          ]
          FILTER (
            DATATYPE(?start) = xsd:dateTime &&
            DATATYPE(?end) = xsd:dateTime
          )
        }
      )
    }.each do |file, query|
      it file do
        about = RDF::URI("http://example.org").join(file)
        input = File.expand_path("../data/#{file}", __FILE__)
        graph = RDF::Graph.load(input, format: :tabular, base_uri: about, logger: logger)

        expect(graph).to pass_query(query, logger: logger, id: about, action: about)
      end
    end
  end
end
