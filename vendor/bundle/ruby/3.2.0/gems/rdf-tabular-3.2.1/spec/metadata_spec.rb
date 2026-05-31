# encoding: UTF-8
$:.unshift "."
require 'spec_helper'

describe RDF::Tabular::Metadata do
  let(:logger) {RDF::Spec.logger}
  before(:each) do
    logger.formatter = lambda {|severity, datetime, progname, msg| "#{severity}: #{msg}\n"}

    WebMock.stub_request(:any, %r(.*example.org.*)).
      to_return(lambda {|request|
        file = request.uri.to_s.split('/').last
        content_type = case file
        when /\.json/ then 'application/json'
        when /\.csv/  then 'text/csv'
        else 'text/plain'
        end

        case file
        when "csv-metadata.json", "country-codes-and-names.csv-metadata.json"
          {status: 401}
        else
          {
            body: File.read(File.expand_path("../data/#{file}", __FILE__)),
            status: 200,
            headers: {'Content-Type' => content_type}
          }
        end
      })
  end

  shared_examples "inherited properties" do |allowed = true|
    {
      aboutUrl: {
        valid: ["http://example.org/example.csv#row={_row}", "http://example.org/tree/{on%2Dstreet}/{GID}", "#row.{_row}"],
        invalid: [1, true, nil, %w(foo bar)]
      },
      datatype: {
        valid: (%w(anyAtomicType string token language Name NCName boolean gYear number binary datetime any xml html json) +
               [{"base" => "string"}]
               ),
        invalid: [1, true, "http://example.org/",
                 {"base" => "foo"},
                 {"base" => "anyType"},
                 {"base" => "anySimpleType"},
                 {"base" => "IDREFS"},
                 ],
        errors: [{"@id" => "_:foo"},
                 {"@id" => "http://www.w3.org/2001/XMLSchema#string"},
               ]
      },
      default: {
        valid: ["foo"],
        invalid: [1, %w(foo bar), true, nil]
      },
      lang: {
        valid: %w(en en-US),
        invalid: %w(1 foo)
      },
      null: {
        valid: ["foo", %w(foo bar)],
        invalid: [1, true, {}]
      },
      ordered: {
        valid: [true, false],
        invalid: [nil, "foo", 1, 0, "true", "false", "TrUe", "fAlSe", "1", "0"],
      },
      propertyUrl: {
        valid: [
          "http://example.org/example.csv#col={_name}",
          "http://example.org/tree/{on%2Dstreet}/{GID}",
          "#row.{_row}"
        ],
        invalid: [1, true, %w(foo bar)]
      },
      required: {
        valid: [true, false],
        invalid: [nil, "foo", 1, 0, "true", "false", "TrUe", "fAlSe", "1", "0"],
      },
      separator: {
        valid: %w(, a | : foo ::) + [nil],
        invalid: [1, false]
      },
      "textDirection" => {
        valid: %w(rtl ltr),
        invalid: %w(foo default)
      },
      valueUrl: {
        valid: [
          "http://example.org/example.csv#row={_row}",
          "http://example.org/tree/{on%2Dstreet}/{GID}",
          "#row.{_row}"
        ],
        invalid: [1, true, nil, %w(foo bar)]
      },
    }.each do |prop, params|
      context prop.to_s do
        if allowed
          it "validates" do
            params.fetch(:valid, {}).each do |v|
              logger.clear
              subject.send("#{prop}=".to_sym, v)
              expect(subject).to be_valid # Causes re-validation
              expect(logger.to_s).not_to match(/ERROR|WARN/)
            end
          end
          it "invalidates" do
            params.fetch(:invalid, {}).each do |v|
              logger.clear
              subject.send("#{prop}=".to_sym, v)
              expect(subject).to be_valid # Causes re-validation
              expect(logger.to_s).not_to include "ERROR"
              expect(logger.to_s).to include "WARN"
            end
          end
          it "errors" do
            params.fetch(:error, {}).each do |v|
              logger.clear
              subject.send("#{prop}=".to_sym, v)
              expect(subject).not_to be_valid # Causes re-validation
              expect(logger.to_s).to include "ERROR"
            end
          end
        else
          it "does not allow" do
            params[:valid].each do |v|
              logger.clear
              subject.send("#{prop}=".to_sym, v)
              expect(subject).to be_valid # Causes re-validation
              expect(logger.to_s).not_to include "ERROR"
              expect(logger.to_s).to include "WARN"
            end
          end
        end
      end
    end
  end

  shared_examples "common properties" do |allowed = true|
    let(:valid) {%w(dc:description dcat:keyword http://schema.org/copyrightHolder)}
    let(:invalid) {%w(foo bar:baz)}
    if allowed
      context "valid JSON-LD" do
        it "allows defined prefixed names and absolute URIs" do
          valid.each do |v|
            logger.clear
            subject[v.to_sym] = "foo"
            expect(subject).to be_valid # Causes re-validation
            expect(logger.to_s).not_to match(/ERROR|WARN/)
          end
        end

        {
          "value object"            => %({"@value": "foo"}),
          "value with type"         => %({"@value": "1", "@type": "xsd:integer"}),
          "value with language"     => %({"@value": "foo", "@language": "en"}),
          "node"                    => %({"@id": "http://example/foo"}),
          "node with pname type"    => %({"@type": "foaf:Person"}),
          "node with URL type"      => %({"@type": "http://example/Person"}),
          "node with array type"    => %({"@type": ["schema:Person", "foaf:Person"]}),
          "node with term type"     => %({"@type": "Table"}),
          "node with term property" => %({"csvw:name": "foo"}),
          "boolean value"           => true,
          "integer value"           => 1,
          "double value"            => 1.1,
        }.each do |name, value|
          specify(name) {
            subject["dc:object"] = value.is_a?(String) ? ::JSON.parse(value) : value
            expect(subject).to be_valid # Causes re-validation
            expect(logger.to_s).not_to match(/ERROR|WARN/)
          }
        end
      end

      context "invalid JSON-LD" do
        it "Does not allow unknown prefxies or unprefixed names" do
          invalid.each do |v|
            logger.clear
            subject[v.to_sym] = "foo"
            expect(subject).to be_valid # Causes re-validation
            expect(logger.to_s).not_to include "ERROR"
            expect(logger.to_s).to include "WARN"
          end
        end

        {
          "value with type and language" => %({"@value": "foo", "@type": "xsd:token", "@language": "en"}),
          "@id and @value" => %({"@id": "http://example/", "@value": "foo"}),
          "value with BNode @id" => %({"@id": "_:foo"}),
          "value with BNode @type" => %({"@type": "_:foo"}),
          "value with BNode property" => %({"_:foo": "bar"}),
          "value with @context" => %({"@context": {}, "@id": "http://example/"}),
          "value with @graph" => %({"@graph": {}}),
        }.each do |name, value|
          specify(name) {
            subject["dc:object"] = ::JSON.parse(value)
            expect(subject).not_to be_valid
            expect(logger.to_s).to include "ERROR"
          }
        end
      end
    else
      it "Does not allow defined prefixed names and absolute URIs" do
        (valid + invalid).each do |v|
          subject[v.to_sym] = "foo"
          expect(subject).to be_valid # Causes re-validation
          expect(logger.to_s).not_to include "ERROR"
          expect(logger.to_s).to include "WARN"
        end
      end
    end
  end

  describe RDF::Tabular::Column do
    subject {described_class.new({"name" => "foo"}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"), logger: logger)}
    specify {is_expected.to be_valid}
    it_behaves_like("inherited properties")
    it_behaves_like("common properties")

    it "allows valid name" do
      %w(
        name abc.123 _col.1
      ).each {|v| expect(described_class.new({"name" => v}, logger: logger)).to be_valid}
      expect(logger.to_s).not_to match(/ERROR|WARN/)
    end

    it "detects invalid names" do
      [1, true, nil, "_foo", "_col=1"].each do |v|
        md = described_class.new({"name" => v}, logger: logger)
        expect(md).to be_valid
        expect(logger.to_s).not_to include "ERROR"
        expect(logger.to_s).to include "WARN"
      end
    end

    it "allows absence of name" do
      expect(described_class.new({"@type" => "Column"}, logger: logger)).to be_valid
      expect(described_class.new({"@type" => "Column"}, logger: logger).name).to eql '_col.0'
      expect(logger.to_s).not_to match(/ERROR|WARN/)
    end

    its(:type) {is_expected.to eql :Column}

    {
      titles: {
        valid: ["foo", %w(foo bar), {"en" => "foo", "de" => "bar"}],
        warning: [1, true, nil]
      },
      suppressOutput: {
        valid: [true, false],
        warning: [nil, "foo", 1, 0, "true", "false", "TrUe", "fAlSe", "1", "0"],
      },
      virtual: {
        valid: [true, false],
        warning: [nil, 1, 0, "true", "false", "TrUe", "fAlSe", "1", "0", "foo"],
      },
    }.each do |prop, params|
      context prop.to_s do
        it "validates" do
          params[:valid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).not_to include "ERROR"
            expect(logger.to_s).not_to include "WARN"
          end
        end
        it "invalidates" do
          params[:invalid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).not_to be_valid
            expect(logger.to_s).to include "ERROR"
          end
        end if params[:invalid]
        it "warnings" do
          params[:warning].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).not_to include "ERROR"
            expect(logger.to_s).to include "WARN"
          end
        end if params[:warning]
      end
    end

    context "titles" do
      {
        string: ["foo", {"und" => ["foo"]}],
      }.each do |name, (input, output)|
        it name do
          subject.titles = input
          expect(subject.normalize!.titles).to produce(output)
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
      end
    end
  end

  describe RDF::Tabular::Schema do
    subject {described_class.new({}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"), logger: logger)}
    specify {is_expected.to be_valid}
    it_behaves_like("inherited properties")
    it_behaves_like("common properties")
    its(:type) {is_expected.to eql :Schema}

    describe "columns" do
      let(:column) {{"name" => "foo"}}
      subject {described_class.new({"columns" => []}, base: RDF::URI("http://example.org/base"), logger: logger)}
      it {is_expected.to be_valid}

      its(:type) {is_expected.to eql :Schema}

      it "allows a valid column" do
        v = described_class.new({"columns" => [column]}, base: RDF::URI("http://example.org/base"), logger: logger)
        expect(v).to be_valid
        expect(logger.to_s).not_to include "ERROR"
      end

      it "is invalid with an invalid column" do
        v = described_class.new({"columns" => [{"name" => "_invalid"}]}, base: RDF::URI("http://example.org/base"), logger: logger)
        expect(v).to be_valid
        expect(logger.to_s).not_to include "ERROR"
        expect(logger.to_s).to include "WARN"
      end

      it "is invalid with an non-unique columns" do
        v = described_class.new({"columns" => [column, column]}, base: RDF::URI("http://example.org/base"), logger: logger)
        expect(v).not_to be_valid
        expect(logger.to_s).to include "ERROR"
      end
    end

    describe "primaryKey" do
      let(:column) {{"name" => "foo"}}
      let(:column2) {{"name" => "bar"}}
      subject {described_class.new({"columns" => [column], "primaryKey" => column["name"]}, base: RDF::URI("http://example.org/base"), logger: logger)}
      specify {is_expected.to be_valid}

      its(:type) {is_expected.to eql :Schema}

      it "is valid if referenced column does not exist" do
        subject[:columns] = []
        expect(subject).to be_valid
        expect(logger.to_s).not_to include "ERROR"
        expect(logger.to_s).to include "WARN"
      end

      it "is valid with multiple names" do
        v = described_class.new({
          "columns" => [column, column2],
          "primaryKey" => [column["name"], column2["name"]]},
          base: RDF::URI("http://example.org/base"),
          logger: logger)
        expect(v).to be_valid
        expect(logger.to_s).not_to match(/ERROR|WARN/)
      end

      it "is valid with multiple names if any column missing" do
        v = described_class.new({
          "columns" => [column],
          "primaryKey" => [column["name"], column2["name"]]},
          base: RDF::URI("http://example.org/base"),
          logger: logger)
        expect(v).to be_valid
        expect(logger.to_s).to include "WARN"
      end
    end

    describe "foreignKeys" do
      subject {
        RDF::Tabular::TableGroup.new({
          "@context" => 'http://www.w3.org/ns/csvw',
          tables: [{
            url: "a",
            tableSchema: {
              "@id" => "a_s",
              columns: [{name: "a1"}, {name: "a2"}],
              foreignKeys: []
            }
          }, {
            url: "b",
            tableSchema: {
              "@id" => "b_s",
              columns: [{name: "b1"}, {name: "b2"}],
              foreignKeys: []
            }
          }]},
          base: RDF::URI("http://example.org/base"), logger: logger
        )
      }
      context "valid" do
        {
          "references single column with resource" => {
            "columnReference" => "a1",
            "reference" => {
              "resource" => "b",
              "columnReference" => "b1"
            }
          },
          "references multiple columns with resource" => {
            "columnReference" => ["a1", "a2"],
            "reference" => {
              "resource" => "b",
              "columnReference" => ["b1", "b2"]
            }
          },
          "references single column with schemaReference" => {
            "columnReference" => "a1",
            "reference" => {
              "schemaReference" => "b_s",
              "columnReference" => "b1"
            }
          }
        }.each do |name, fk|
          it name do
            subject.tables.first.tableSchema.foreignKeys << fk
            subject.normalize!
            expect(subject).to be_valid
            expect(logger.to_s).not_to match(/ERROR|WARN/)
          end
        end
      end

      context "invalid" do
        {
          "missing source column" => {
            "columnReference" => "not_here",
            "reference" => {
              "resource" => "b",
              "columnReference" => "b1"
            }
          },
          "one missing source column" => {
            "columnReference" => ["a1", "not_here"],
            "reference" => {
              "resource" => "b",
              "columnReference" => ["b1", "b2"]
            }
          },
          "missing destination column" => {
            "columnReference" => "a1",
            "reference" => {
              "resource" => "b",
              "columnReference" => "not_there"
            }
          },
          "missing resource" => {
            "columnReference" => "a1",
            "reference" => {
              "resource" => "not_here",
              "columnReference" => "b1"
            }
          },
          "missing tableSchema" => {
            "columnReference" => "a1",
            "reference" => {
              "schemaReference" => "not_here",
              "columnReference" => "b1"
            }
          },
          "both resource and tableSchema" => {
            "columnReference" => "a1",
            "reference" => {
              "resource" => "b",
              "schemaReference" => "b_s",
              "columnReference" => "b1"
            }
          },
        }.each do |name, fk|
          it name do
            subject.tables.first.tableSchema.foreignKeys << fk
            subject.normalize!
            subject.inspect
            expect(subject).not_to be_valid
            expect(logger.to_s).to include "ERROR"
          end
        end
      end
    end
  end

  describe RDF::Tabular::Transformation do
    let(:targetFormat) {"http://example.org/targetFormat"}
    let(:scriptFormat) {"http://example.org/scriptFormat"}
    subject {
      described_class.new({
        "url" => "http://example/",
        "targetFormat" => targetFormat,
        "scriptFormat" => scriptFormat},
      context: "http://www.w3.org/ns/csvw",
      base: RDF::URI("http://example.org/base"),
      logger: logger)
    }
    specify {is_expected.to be_valid}
    it_behaves_like("inherited properties", false)
    it_behaves_like("common properties")
    its(:type) {is_expected.to eql :Template}

    {
      source: {
        valid: %w(json rdf) + [nil],
        warning: [1, true, {}]
      },
    }.each do |prop, params|
      context prop.to_s do
        it "validates" do
          params[:valid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
          end
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
        it "warnings" do
          params[:warning].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).to include "WARN"
          end
        end
      end
    end

    context "titles" do
      {
        string: ["foo", {"und" => ["foo"]}],
      }.each do |name, (input, output)|
        it name do
          subject.titles = input
          expect(subject.normalize!.titles).to produce(output)
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
      end
    end
  end

  describe RDF::Tabular::Dialect do
    subject {described_class.new({}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"), logger: logger)}
    specify {is_expected.to be_valid}
    it_behaves_like("inherited properties", false)
    it_behaves_like("common properties", false)
    its(:type) {is_expected.to eql :Dialect}

    described_class.const_get(:DEFAULTS).each do |p, v|
      context "#{p}" do
        it "retrieves #{v.inspect} by default" do
          expect(logger.to_s).not_to match(/ERROR|WARN/)
          expect(subject.send(p)).to eql v
        end

        it "retrieves set value" do
          subject[p] = "foo"
          expect(subject.send(p)).to eql "foo"
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
      end
    end

    describe "#embedded_metadata" do
      {
        "with defaults" => {
          input: "https://example.org/countries.csv",
          result: %({
            "@context": "http://www.w3.org/ns/csvw",
            "@type": "Table",
            "url": "https://example.org/countries.csv",
            "tableSchema": {
              "@type": "Schema",
              "columns": [
                {"titles": {"und": ["countryCode"]}},
                {"titles": {"und": ["latitude"]}},
                {"titles": {"und": ["longitude"]}},
                {"titles": {"und": ["name"]}}
              ]
            }
          })
        },
        "with skipRows" => {
          input: "https://example.org/countries.csv",
          dialect: {skipRows: 1},
          result: %({
            "@context": "http://www.w3.org/ns/csvw",
            "@type": "Table",
            "url": "https://example.org/countries.csv",
            "tableSchema": {
              "@type": "Schema",
              "columns": [
                {"titles": {"und": ["AD"]}},
                {"titles": {"und": ["42.546245"]}},
                {"titles": {"und": ["1.601554"]}},
                {"titles": {"und": ["Andorra"]}}
              ]
            },
            "rdfs:comment": ["countryCode,latitude,longitude,name"]
          })
        },
        "delimiter" => {
          input: "https://example.org/tree-ops.tsv",
          dialect: {delimiter: "\t"},
          result: %({
            "@context": "http://www.w3.org/ns/csvw",
            "@type": "Table",
            "url": "https://example.org/tree-ops.tsv",
            "tableSchema": {
              "@type": "Schema",
              "columns": [
                {"titles": {"und": ["GID"]}},
                {"titles": {"und": ["On Street"]}},
                {"titles": {"und": ["Species"]}},
                {"titles": {"und": ["Trim Cycle"]}},
                {"titles": {"und": ["Inventory Date"]}}
              ]
            }
          })
        },
      }.each do |name, props|
        it name do
          dialect = if props[:dialect]
            described_class.new(props[:dialect], logger: logger)
          else
            subject
          end

          result = dialect.embedded_metadata(props[:input], nil, base: RDF::URI("http://example.org/base"))
          expect(::JSON.parse(result.to_json(JSON_STATE))).to produce(::JSON.parse(props[:result]), logger)
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
      end
    end
  end

  describe RDF::Tabular::Table do
    subject {described_class.new({"url" => "http://example.org/table.csv"}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"), logger: logger)}
    specify {is_expected.to be_valid}      
    it_behaves_like("inherited properties")
    it_behaves_like("common properties")
    its(:type) {is_expected.to eql :Table}

    describe "#to_table_group" do
      it "should be tested"
    end

    {
      tableSchema: {
        valid: [RDF::Tabular::Schema.new({})],
        warning: [1, true, nil]
      },
      notes: {
        valid: [{}, [{}]],
        invalid: [1, true, nil]
      },
      tableDirection: {
        valid: %w(rtl ltr auto),
        warning: %w(foo true 1)
      },
      transformations: {
        valid: [[RDF::Tabular::Transformation.new({url: "http://example", targetFormat: "http://example", scriptFormat: "http://example/"}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"))]],
        warning: [RDF::Tabular::Transformation.new({url: "http://example", targetFormat: "http://example", scriptFormat: "http://example/"}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"))] +
                 %w(foo true 1)
      },
      dialect: {
        valid: [{skipRows: 1}],
        warning: [1]
      },
      suppressOutput: {
        valid: [true, false],
        warning: [nil, "foo", 1, 0, "true", "false", "TrUe", "fAlSe", "1", "0"],
      },
    }.each do |prop, params|
      context prop.to_s do
        it "validates" do
          params[:valid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).not_to match(/ERROR|WARN/)
          end
        end
        it "invalidates" do
          params[:invalid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).not_to be_valid
            expect(logger.to_s).to include("ERROR")
          end
        end if params[:invalid]
        it "warnings" do
          params[:warning].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).to include("WARN")
          end
        end if params[:warning]
      end
    end
  end

  describe RDF::Tabular::TableGroup do
    let(:table) {{"url" => "http://example.org/table.csv"}}
    subject {described_class.new({"tables" => [table]}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"), logger: logger)}
    specify {is_expected.to be_valid}
    
    it_behaves_like("inherited properties")
    it_behaves_like("common properties")
    its(:type) {is_expected.to eql :TableGroup}
    {
      tableSchema: {
        valid: [RDF::Tabular::Schema.new({})],
        warning: [1, true, nil]
      },
      tableDirection: {
        valid: %w(rtl ltr auto),
        warning: %w(foo true 1)
      },
      dialect: {
        valid: [{skipRows: 1}],
        warning: [1]
      },
      transformations: {
        valid: [[RDF::Tabular::Transformation.new({url: "http://example", targetFormat: "http://example", scriptFormat: "http://example/"}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"))]],
        warning: [RDF::Tabular::Transformation.new({url: "http://example", targetFormat: "http://example", scriptFormat: "http://example/"}, context: "http://www.w3.org/ns/csvw", base: RDF::URI("http://example.org/base"))] +
                 %w(foo true 1)
      },
      notes: {
        valid: [{}, [{}]],
        invalid: [1, true, nil]
      },
    }.each do |prop, params|
      context prop.to_s do
        it "validates" do
          params[:valid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).not_to match(/ERROR|WARN/)
          end
        end
        it "invalidates" do
          params[:invalid].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).not_to be_valid
            expect(logger.to_s).to include("ERROR")
          end
        end if params[:invalid]
        it "warnings" do
          params[:warning].each do |v|
            subject.send("#{prop}=".to_sym, v)
            expect(subject).to be_valid
            expect(logger.to_s).to include("WARN")
          end
        end if params[:warning]
      end
    end
  end

  context "parses example metadata" do
    Dir.glob(File.expand_path("../data/*.json", __FILE__)).each do |filename|
      next if filename =~ /-(atd|standard|minimal|roles).json/
      context filename do
        subject {RDF::Tabular::Metadata.open(filename, logger: logger)}
        it {is_expected.to be_valid}
        its(:filenames) {is_expected.to include("file:#{filename}")}
      end
      after(:each) do
        expect(logger.to_s).not_to match(/ERROR|WARN/)
      end
    end
  end

  context "parses invalid metadata" do
    Dir.glob(File.expand_path("../invalid_data/*.json", __FILE__)).each do |filename|
      context filename do
        subject {RDF::Tabular::Metadata.open(filename, logger: logger)}
        File.foreach(filename.sub(".json", "-errors.txt")) do |err|
          it {is_expected.not_to be_valid}
        end
        after(:each) do
          expect(logger.to_s).not_to include("ERROR")
        end
      end
    end
  end

  context "object properties" do
    let(:table) {{"url" => "http://example.org/table.csv", "@type" => "Table"}}
    it "loads referenced schema" do
      table[:tableSchema] = "http://example.org/schema"
      expect(described_class).to receive(:open).with(table[:tableSchema], kind_of(Hash)).and_return(RDF::Tabular::Schema.new({"@type" => "Schema"}, base: RDF::URI("http://example.org/base")))
      allow_any_instance_of(described_class).to receive(:normalize!).and_return(true)
      described_class.new(table, base: RDF::URI("http://example.org/base"), logger: logger)
    end
    it "loads referenced dialect" do
      table[:dialect] = "http://example.org/dialect"
      expect(described_class).to receive(:open).with(table[:dialect], kind_of(Hash)).and_return(RDF::Tabular::Dialect.new({}))
      allow_any_instance_of(described_class).to receive(:normalize!).and_return(true)
      described_class.new(table, base: RDF::URI("http://example.org/base"), logger: logger)
    end
  end

  context "inherited properties" do
    let(:table) {{"url" => "http://example.org/table.csv", "tableSchema" => {"@type" => "Schema"}, "@type" => "Table"}}
    subject {described_class.new(table, base: RDF::URI("http://example.org/base"), logger: logger)}

    it "inherits properties from parent" do
      subject.lang = "en"
      expect(subject.tableSchema.lang).to eql "en" 
    end

    it "overrides properties in parent" do
      subject.lang = "en"
      subject.tableSchema.lang = "de"
      expect(subject.tableSchema.lang).to eql "de" 
    end
  end

  describe ".open" do
    context "validates example metadata" do
      Dir.glob(File.expand_path("../data/*.json", __FILE__)).each do |filename|
        next if filename =~ /-(atd|standard|minimal|roles).json/
        context filename do
          subject {RDF::Tabular::Metadata.open(filename, logger: logger)}
          it {is_expected.to be_valid}
          it do
            subject.validate
            expect(logger.to_s).to be_empty
          end
          its(:filenames) {is_expected.to include("file:#{filename}")}
        end
      end
    end
  end

  describe ".from_input" do
    it "FIXME"
  end

  describe ".new" do
    context "intuits subclass" do
      {
        ":type TableGroup" => [{}, {type: :TableGroup}, RDF::Tabular::TableGroup],
        ":type Table" => [{}, {type: :Table}, RDF::Tabular::Table],
        ":type Template" => [{}, {type: :Template}, RDF::Tabular::Transformation],
        ":type Schema" => [{}, {type: :Schema}, RDF::Tabular::Schema],
        ":type Column" => [{}, {type: :Column}, RDF::Tabular::Column],
        ":type Dialect" => [{}, {type: :Dialect}, RDF::Tabular::Dialect],
        "tables TableGroup" => [{"tables" => []}, RDF::Tabular::TableGroup],
        "dialect Table" => [{"dialect" => {}}, RDF::Tabular::Table],
        "tableSchema Table" => [{"tableSchema" => {}}, RDF::Tabular::Table],
        "transformations Table" => [{"transformations" => []}, RDF::Tabular::Table],
        "targetFormat Transformation" => [{"targetFormat" => "http://foo"}, RDF::Tabular::Transformation],
        "scriptFormat Transformation" => [{"scriptFormat" => "http://foo"}, RDF::Tabular::Transformation],
        "source Transformation" => [{"source" => "json"}, RDF::Tabular::Transformation],
        "columns Schema" => [{"columns" => []}, RDF::Tabular::Schema],
        "primaryKey Schema" => [{"primaryKey" => "foo"}, RDF::Tabular::Schema],
        "foreignKeys Schema" => [{"foreignKeys" => []}, RDF::Tabular::Schema],
        "commentPrefix Dialect" => [{"commentPrefix" => "#"}, RDF::Tabular::Dialect],
        "delimiter Dialect" => [{"delimiter" => ","}, RDF::Tabular::Dialect],
        "doubleQuote Dialect" => [{"doubleQuote" => true}, RDF::Tabular::Dialect],
        "encoding Dialect" => [{"encoding" => "utf-8"}, RDF::Tabular::Dialect],
        "header Dialect" => [{"header" => true}, RDF::Tabular::Dialect],
        "headerRowCount Dialect" => [{"headerRowCount" => 1}, RDF::Tabular::Dialect],
        "lineTerminators Dialect" => [{"lineTerminators" => "\r\n"}, RDF::Tabular::Dialect],
        "quoteChar Dialect" => [{"quoteChar" => "\""}, RDF::Tabular::Dialect],
        "skipBlankRows Dialect" => [{"skipBlankRows" => true}, RDF::Tabular::Dialect],
        "skipColumns Dialect" => [{"skipColumns" => 0}, RDF::Tabular::Dialect],
        "skipInitialSpace Dialect" => [{"skipInitialSpace" => true}, RDF::Tabular::Dialect],
        "skipRows Dialect" => [{"skipRows" => 1}, RDF::Tabular::Dialect],
        "trim Dialect" => [{"trim" => true}, RDF::Tabular::Dialect],
      }.each do |name, args|
        it name do
          klass = args.pop
          input, options = args
          options ||= {}
          options[:logger] = logger
          options[:context] ||= 'http://www.w3.org/ns/csvw'
          expect(described_class.new(input, **options)).to be_a(klass)
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
      end
    end
  end

  describe "#each_row" do
    subject {
      described_class.new(JSON.parse(%({
        "url": "https://example.org/countries.csv",
        "@type": "Table",
        "tableSchema": {
          "@type": "Schema",
          "columns": [{
            "name": "countryCode",
            "titles": "countryCode",
            "propertyUrl": "https://example.org/countries.csv#countryCode"
          }, {
            "name": "latitude",
            "titles": "latitude",
            "propertyUrl": "https://example.org/countries.csv#latitude"
          }, {
            "name": "longitude",
            "titles": "longitude",
            "propertyUrl": "https://example.org/countries.csv#longitude"
          }, {
            "name": "name",
            "titles": "name",
            "propertyUrl": "https://example.org/countries.csv#name"
          }]
        }
      })), base: RDF::URI("http://example.org/base"), logger: logger)
    }
    let(:input) {RDF::Util::File.open_file("https://example.org/countries.csv")}

    specify {expect {|b| subject.each_row(input, &b)}.to yield_control.exactly(3)}

    it "returns consecutive row numbers" do
      nums = subject.to_enum(:each_row, input).map(&:number)
      expect(nums).to eql([1, 2, 3])
    end

    it "returns cells" do
      subject.each_row(input) do |row|
        expect(row).to be_a(RDF::Tabular::Row)
        expect(row.values.length).to eql 4
        expect(row.values.map(&:class).compact).to include(RDF::Tabular::Row::Cell)
      end
    end

    it "has nil aboutUrls" do
      subject.each_row(input) do |row|
        expect(row.values[0].aboutUrl).to be_nil
        expect(row.values[1].aboutUrl).to be_nil
        expect(row.values[2].aboutUrl).to be_nil
        expect(row.values[3].aboutUrl).to be_nil
      end
    end

    it "has expected propertyUrls" do
      subject.each_row(input) do |row|
        expect(row.values[0].propertyUrl).to eq "https://example.org/countries.csv#countryCode"
        expect(row.values[1].propertyUrl).to eq "https://example.org/countries.csv#latitude"
        expect(row.values[2].propertyUrl).to eq "https://example.org/countries.csv#longitude"
        expect(row.values[3].propertyUrl).to eq "https://example.org/countries.csv#name"
      end
    end

    it "has expected valueUrls" do
      subject.each_row(input) do |row|
        expect(row.values[0].valueUrl).to be_nil
        expect(row.values[1].valueUrl).to be_nil
        expect(row.values[2].valueUrl).to be_nil
        expect(row.values[3].valueUrl).to be_nil
      end
    end

    it "has expected values" do
      rows = subject.to_enum(:each_row, input).to_a
      expect(rows[0].values.map(&:to_s)).to produce(%w(AD 42.546245 1.601554 Andorra), logger)
      expect(rows[1].values.map(&:to_s)).to produce((%w(AE 23.424076 53.847818) << "United Arab Emirates"), logger)
      expect(rows[2].values.map(&:to_s)).to produce(%w(AF 33.93911 67.709953 Afghanistan), logger)
    end

    context "URL expansion" do
      subject {
        JSON.parse(%({
          "url": "https://example.org/countries.csv",
          "tableSchema": {
            "columns": [
              {"titles": "addressCountry"},
              {"titles": "latitude"},
              {"titles": "longitude"},
              {"titles": "name"}
            ]
          }
        }))
      }
      let(:input) {RDF::Util::File.open_file("https://example.org/countries.csv")}

      {
        "default titles" => {
          aboutUrl: [RDF::Node, RDF::Node, RDF::Node, RDF::Node],
          propertyUrl: [nil, nil, nil, nil],
          valueUrl: [nil, nil, nil, nil],
          md: {}
        },
        "schema transformations" => {
          aboutUrl: %w(#addressCountry #latitude #longitude #name),
          propertyUrl: %w(?_name=addressCountry ?_name=latitude ?_name=longitude ?_name=name),
          valueUrl: %w(addressCountry latitude longitude name),
          md: {
            "aboutUrl" => "{#_name}",
            "propertyUrl" => '{?_name}',
            "valueUrl" => '{_name}'
          }
        },
        "PNames" => {
          aboutUrl: [RDF::Vocab::SCHEMA.addressCountry, RDF::Vocab::SCHEMA.latitude, RDF::Vocab::SCHEMA.longitude, RDF::Vocab::SCHEMA.name],
          propertyUrl: [RDF::Vocab::SCHEMA.addressCountry, RDF::Vocab::SCHEMA.latitude, RDF::Vocab::SCHEMA.longitude, RDF::Vocab::SCHEMA.name],
          valueUrl: [RDF::Vocab::SCHEMA.addressCountry, RDF::Vocab::SCHEMA.latitude, RDF::Vocab::SCHEMA.longitude, RDF::Vocab::SCHEMA.name],
          md: {
            "aboutUrl" => "http://schema.org/{_name}",
            "propertyUrl" => 'schema:{_name}',
            "valueUrl" => 'schema:{_name}'
          }
        },
      }.each do |name, props|
        context name do
          let(:md) {RDF::Tabular::Table.new(subject.merge(props[:md]), base: RDF::URI("http://example.org/base"), logger: logger).normalize!}
          let(:cells) {md.to_enum(:each_row, input).to_a.first.values}
          let(:aboutUrls) {props[:aboutUrl].map {|u| u.is_a?(String) ? md.url.join(u) : u}}
          let(:propertyUrls) {props[:propertyUrl].map {|u| u.is_a?(String) ? md.url.join(u) : u}}
          let(:valueUrls) {props[:valueUrl].map {|u| u.is_a?(String) ? md.url.join(u) : u}}
          it "aboutUrl is #{props[:aboutUrl]}" do
            if aboutUrls.first == RDF::Node
              expect(cells.map(&:aboutUrl)).to all(be_nil)
            else
              expect(cells.map(&:aboutUrl)).to include(*aboutUrls)
            end
          end
          it "propertyUrl is #{props[:propertyUrl]}" do
            expect(cells.map(&:propertyUrl)).to include(*propertyUrls)
          end
          it "valueUrl is #{props[:valueUrl]}" do
            expect(cells.map(&:valueUrl)).to include(*valueUrls)
          end
        end
      end
    end
    it "expands aboutUrl in cells"

    context "variations" do
      {
        "skipRows" => {dialect: {skipRows: 1}},
        "headerRowCount" => {dialect: {headerRowCount: 0}},
        "skipRows + headerRowCount" => {dialect: {skipRows: 1, headerRowCount: 0}},
        "skipColumns" => {dialect: {skipColumns: 1}},
      }.each do |name, props|
        context name do
          subject {
            raw = JSON.parse(%({
              "url": "https://example.org/countries.csv",
              "@type": "Table",
              "tableSchema": {
                "@type": "Schema",
                "columns": [{
                  "name": "countryCode",
                  "titles": "countryCode",
                  "propertyUrl": "https://example.org/countries.csv#countryCode"
                }, {
                  "name": "latitude",
                  "titles": "latitude",
                  "propertyUrl": "https://example.org/countries.csv#latitude"
                }, {
                  "name": "longitude",
                  "titles": "longitude",
                  "propertyUrl": "https://example.org/countries.csv#longitude"
                }, {
                  "name": "name",
                  "titles": "name",
                  "propertyUrl": "https://example.org/countries.csv#name"
                }]
              }
            }))
            raw["dialect"] = props[:dialect]
            described_class.new(raw, base: RDF::URI("http://example.org/base"), logger: logger)
          }
          let(:rows) {subject.to_enum(:each_row, input).to_a}
          let(:rowOffset) {props[:dialect].fetch(:skipRows, 0) + props[:dialect].fetch(:headerRowCount, 1)}
          let(:columnOffset) {props[:dialect].fetch(:skipColumns, 0)}
          it "has expected number attributes" do
            nums = [1, 2, 3, 4]
            nums = nums.first(nums.length - rowOffset)
            expect(rows.map(&:number)).to eql nums
          end
          it "has expected sourceNumber attributes" do
            nums = [1, 2, 3, 4].map {|n| n + rowOffset}
            nums = nums.first(nums.length - rowOffset)
            expect(rows.map(&:sourceNumber)).to eql nums
          end
          it "has expected column.number attributes" do
            nums = [1, 2, 3, 4]
            nums = nums.first(nums.length - columnOffset)
            expect(rows.first.values.map {|c| c.column.number}).to eql nums
          end
          it "has expected column.sourceNumber attributes" do
            nums = [1, 2, 3, 4].map {|n| n + columnOffset}
            nums = nums.first(nums.length - columnOffset)
            expect(rows.first.values.map {|c| c.column.sourceNumber}).to eql nums
          end
        end
      end

      context "virtual columns" do
        subject {
          described_class.new(JSON.parse(%({
            "@context": "http://www.w3.org/ns/csvw",
            "url": "https://example.org/countries.csv",
            "aboutUrl": "https://example.org/countries",
            "@type": "Table",
            "tableSchema": {
              "@type": "Schema",
              "columns": [{
                "name": "countryCode",
                "titles": "countryCode",
                "propertyUrl": "https://example.org/countries.csv#countryCode"
              }, {
                "name": "latitude",
                "titles": "latitude",
                "propertyUrl": "https://example.org/countries.csv#latitude"
              }, {
                "name": "longitude",
                "titles": "longitude",
                "propertyUrl": "https://example.org/countries.csv#longitude"
              }, {
                "name": "name",
                "titles": "name",
                "propertyUrl": "https://example.org/countries.csv#name"
              }, {
                "virtual": true,
                "propertyUrl": "https://example.org/countries.csv#virt1",
                "valueUrl": "https://example.org/countries.csv#virt1"
              }, {
                "virtual": true,
                "propertyUrl": "https://example.org/countries.csv#virt2",
                "default": "default",
                "datatype": "string"
              }]
            }
          })), base: RDF::URI("http://example.org/base"), logger: logger)
        }
        let(:input) {RDF::Util::File.open_file("https://example.org/countries.csv")}
        let(:rows) {subject.to_enum(:each_row, input).to_a}

        it "has expected aboutUrls" do
          subject.each_row(input) do |row|
            expect(row.values[0].aboutUrl).to eq "https://example.org/countries"
            expect(row.values[1].aboutUrl).to eq "https://example.org/countries"
            expect(row.values[2].aboutUrl).to eq "https://example.org/countries"
            expect(row.values[3].aboutUrl).to eq "https://example.org/countries"
            expect(row.values[4].aboutUrl).to eq "https://example.org/countries"
            expect(row.values[5].aboutUrl).to eq "https://example.org/countries"
          end
        end

        it "has expected propertyUrls" do
          subject.each_row(input) do |row|
            expect(row.values[0].propertyUrl).to eq "https://example.org/countries.csv#countryCode"
            expect(row.values[1].propertyUrl).to eq "https://example.org/countries.csv#latitude"
            expect(row.values[2].propertyUrl).to eq "https://example.org/countries.csv#longitude"
            expect(row.values[3].propertyUrl).to eq "https://example.org/countries.csv#name"
            expect(row.values[4].propertyUrl).to eq "https://example.org/countries.csv#virt1"
            expect(row.values[5].propertyUrl).to eq "https://example.org/countries.csv#virt2"
          end
        end

        it "has expected valueUrls" do
          subject.each_row(input) do |row|
            expect(row.values[0].valueUrl).to be_nil
            expect(row.values[1].valueUrl).to be_nil
            expect(row.values[2].valueUrl).to be_nil
            expect(row.values[3].valueUrl).to be_nil
            expect(row.values[4].valueUrl).to eq "https://example.org/countries.csv#virt1"
            expect(row.values[5].valueUrl).to be_nil
          end
        end

        it "has expected values" do
          rows = subject.to_enum(:each_row, input).to_a
          expect(rows[0].values.map(&:to_s)).to produce(%w(AD 42.546245 1.601554 Andorra).push("", "default"), logger)
          expect(rows[1].values.map(&:to_s)).to produce((%w(AE 23.424076 53.847818).push("United Arab Emirates", "", "default")), logger)
          expect(rows[2].values.map(&:to_s)).to produce(%w(AF 33.93911 67.709953 Afghanistan).push("", "default"), logger)
        end
      end
      
    end

    context "datatypes" do
      {
        # Strings
        "string with no constraints" => {base: "string", value: "foo", result: "foo"},
        "string with matching length" => {base: "string", value: "foo", length: 3, result: "foo"},
        "string matching null when required" => {base: "string", value: "NULL", null: "NULL", required: true},
        "string with wrong length" => {
          base: "string",
          value: "foo",
          length: 4,
          errors: ["foo does not have length 4"]
        },
        "string with wrong maxLength" => {
          base: "string",
          value: "foo",
          maxLength: 2,
          errors: ["foo does not have length <= 2"]
        },
        "string with wrong minLength" => {
          base: "string",
          value: "foo",
          minLength: 4,
          errors: ["foo does not have length >= 4"]
        },

        # Numbers
        "decimal with no constraints" => {
          base: "decimal",
          value: "4"
        },
        "decimal with matching pattern" => {
          base: "decimal",
          format: {"pattern" => '000'},
          value: "123"
        },
        "decimal with explicit groupChar" => {
          base: "decimal",
          format: {"groupChar" => ";"},
          value: "123;456.789",
          result: "123456.789"
        },
        "decimal with repeated groupChar" => {
          base: "decimal",
          format: {"groupChar" => ";"},
          value: "123;;456.789",
          result: "123;;456.789",
          errors: [/does not match numeric pattern/]
        },
        "decimal with explicit decimalChar" => {
          base: "decimal",
          format: {"decimalChar" => ";"},
          value: "123456;789",
          result: "123456.789"
        },
        "invalid decimal" => {
          base: "decimal",
          value: "123456.789e10",
          result: "123456.789e10",
          errors: ["123456.789e10 is not a valid decimal"]
        },
        "decimal with percent" => {
          base: "decimal",
          format: {"groupChar" => ","},
          value: "123456.789%",
          result: "1234.56789"
        },
        "decimal with per-mille" => {
          base: "decimal",
          format: {"groupChar" => ","},
          value: "123456.789‰",
          result: "123.456789"
        },
        "valid integer" => {base: "integer", value: "1234"},
        "invalid integer" => {base: "integer", value: "1234.56", errors: ["1234.56 is not a valid integer"]},
        "valid long" => {base: "long", value: "1234"},
        "invalid long" => {base: "long", value: "1234.56", errors: ["1234.56 is not a valid long"]},
        "valid short" => {base: "short", value: "1234"},
        "invalid short" => {base: "short", value: "1234.56", errors: ["1234.56 is not a valid short"]},
        "valid byte" => {base: "byte", value: "123"},
        "invalid byte" => {base: "byte", value: "1234", errors: ["1234 is not a valid byte"]},
        "valid unsignedLong" => {base: "unsignedLong", value: "1234"},
        "invalid unsignedLong" => {base: "unsignedLong", value: "-1234", errors: ["-1234 is not a valid unsignedLong"]},
        "valid unsignedShort" => {base: "unsignedShort", value: "1234"},
        "invalid unsignedShort" => {base: "unsignedShort", value: "-1234", errors: ["-1234 is not a valid unsignedShort"]},
        "valid unsignedByte" => {base: "unsignedByte", value: "123"},
        "invalid unsignedByte" => {base: "unsignedByte", value: "-123", errors: ["-123 is not a valid unsignedByte"]},
        "valid positiveInteger" => {base: "positiveInteger", value: "123"},
        "invalid positiveInteger" => {base: "positiveInteger", value: "-123", errors: ["-123 is not a valid positiveInteger"]},
        "valid negativeInteger" => {base: "negativeInteger", value: "-123"},
        "invalid negativeInteger" => {base: "negativeInteger", value: "123", errors: ["123 is not a valid negativeInteger"]},
        "valid nonPositiveInteger" => {base: "nonPositiveInteger", value: "0"},
        "invalid nonPositiveInteger" => {base: "nonPositiveInteger", value: "1", errors: ["1 is not a valid nonPositiveInteger"]},
        "valid nonNegativeInteger" => {base: "nonNegativeInteger", value: "0"},
        "invalid nonNegativeInteger" => {base: "nonNegativeInteger", value: "-1", errors: ["-1 is not a valid nonNegativeInteger"]},
        "valid double" => {base: "double", value: "1234.456e789"},
        "invalid double" => {base: "double", value: "1z", errors: ["1z is not a valid double"]},
        "NaN double" => {base: "double", value: "NaN", result: "NaN"},
        "INF double" => {base: "double", value: "INF"},
        "-INF double" => {base: "double", value: "-INF"},
        "valid number" => {base: "number", value: "1234.456e789"},
        "invalid number" => {base: "number", value: "1z", errors: ["1z is not a valid number"]},
        "NaN number" => {base: "number", value: "NaN", result: "NaN"},
        "INF number" => {base: "number", value: "INF"},
        "-INF number" => {base: "number", value: "-INF"},
        "valid float" => {base: "float", value: "1234.456e7"},
        "invalid float" => {base: "float", value: "1z", errors: ["1z is not a valid float"]},
        "NaN float" => {base: "float", value: "NaN", result: "NaN"},
        "INF float" => {base: "float", value: "INF"},
        "-INF float" => {base: "float", value: "-INF"},

        # Booleans
        "valid boolean true" => {base: "boolean", value: "true"},
        "valid boolean false" => {base: "boolean", value: "false"},
        "valid boolean 1" => {base: "boolean", value: "1", result: "true"},
        "valid boolean 0" => {base: "boolean", value: "0", result: "false"},
        "valid boolean Y|N Y" => {base: "boolean", value: "Y", format: "Y|N", result: "true"},
        "valid boolean Y|N N" => {base: "boolean", value: "N", format: "Y|N", result: "false"},

        # Dates
        "valid date yyyy-MM-dd" => {base: "date", value: "2015-03-22", format: "yyyy-MM-dd", result: "2015-03-22"},
        "valid date yyyyMMdd" => {base: "date", value: "20150322", format: "yyyyMMdd", result: "2015-03-22"},
        "valid date dd-MM-yyyy" => {base: "date", value: "22-03-2015", format: "dd-MM-yyyy", result: "2015-03-22"},
        "valid date d-M-yyyy" => {base: "date", value: "22-3-2015", format: "d-M-yyyy", result: "2015-03-22"},
        "valid date MM-dd-yyyy" => {base: "date", value: "03-22-2015", format: "MM-dd-yyyy", result: "2015-03-22"},
        "valid date M-d-yyyy" => {base: "date", value: "3-22-2015", format: "M-d-yyyy", result: "2015-03-22"},
        "valid date dd/MM/yyyy" => {base: "date", value: "22/03/2015", format: "dd/MM/yyyy", result: "2015-03-22"},
        "valid date d/M/yyyy" => {base: "date", value: "22/3/2015", format: "d/M/yyyy", result: "2015-03-22"},
        "valid date MM/dd/yyyy" => {base: "date", value: "03/22/2015", format: "MM/dd/yyyy", result: "2015-03-22"},
        "valid date M/d/yyyy" => {base: "date", value: "3/22/2015", format: "M/d/yyyy", result: "2015-03-22"},
        "valid date dd.MM.yyyy" => {base: "date", value: "22.03.2015", format: "dd.MM.yyyy", result: "2015-03-22"},
        "valid date d.M.yyyy" => {base: "date", value: "22.3.2015", format: "d.M.yyyy", result: "2015-03-22"},
        "valid date MM.dd.yyyy" => {base: "date", value: "03.22.2015", format: "MM.dd.yyyy", result: "2015-03-22"},
        "valid date M.d.yyyy" => {base: "date", value: "3.22.2015", format: "M.d.yyyy", result: "2015-03-22"},

        # Times
        "valid time HH:mm:ss.S" => {base: "time", value: "15:02:37.1", format: "HH:mm:ss.S", result: "15:02:37.1"},
        "valid time HH:mm:ss" => {base: "time", value: "15:02:37", format: "HH:mm:ss", result: "15:02:37"},
        "valid time HHmmss" => {base: "time", value: "150237", format: "HHmmss", result: "15:02:37"},
        "valid time HH:mm" => {base: "time", value: "15:02", format: "HH:mm", result: "15:02:00"},
        "valid time HHmm" => {base: "time", value: "1502", format: "HHmm", result: "15:02:00"},

        # DateTimes
        "valid dateTime yyyy-MM-ddTHH:mm:ss" => {base: "dateTime", value: "2015-03-15T15:02:37", format: "yyyy-MM-ddTHH:mm:ss", result: "2015-03-15T15:02:37"},
        "valid dateTime yyyy-MM-ddTHH:mm:ss.S" => {base: "dateTime", value: "2015-03-15T15:02:37.1", format: "yyyy-MM-ddTHH:mm:ss.S", result: "2015-03-15T15:02:37.1"},
        "valid dateTime yyyy-MM-dd HH:mm:ss" => {base: "dateTime", value: "2015-03-15 15:02:37", format: "yyyy-MM-dd HH:mm:ss", result: "2015-03-15T15:02:37"},
        "valid dateTime yyyyMMdd HHmmss"   => {base: "dateTime", value: "20150315 150237",   format: "yyyyMMdd HHmmss",   result: "2015-03-15T15:02:37"},
        "valid dateTime dd-MM-yyyy HH:mm" => {base: "dateTime", value: "15-03-2015 15:02", format: "dd-MM-yyyy HH:mm", result: "2015-03-15T15:02:00"},
        "valid dateTime d-M-yyyy HHmm"   => {base: "dateTime", value: "15-3-2015 1502",  format: "d-M-yyyy HHmm",   result: "2015-03-15T15:02:00"},
        "valid dateTime yyyy-MM-ddTHH:mm"   => {base: "dateTime", value: "2015-03-15T15:02",  format: "yyyy-MM-ddTHH:mm",   result: "2015-03-15T15:02:00"},
        "valid dateTimeStamp d-M-yyyy HHmm X"   => {base: "dateTimeStamp", value: "15-3-2015 1502 Z",  format: "d-M-yyyy HHmm X",   result: "2015-03-15T15:02:00Z"},
        "valid datetime yyyy-MM-ddTHH:mm:ss" => {base: "datetime", value: "2015-03-15T15:02:37", format: "yyyy-MM-ddTHH:mm:ss", result: "2015-03-15T15:02:37"},
        "valid datetime yyyy-MM-dd HH:mm:ss" => {base: "datetime", value: "2015-03-15 15:02:37", format: "yyyy-MM-dd HH:mm:ss", result: "2015-03-15T15:02:37"},
        "valid datetime yyyyMMdd HHmmss"   => {base: "datetime", value: "20150315 150237",   format: "yyyyMMdd HHmmss",   result: "2015-03-15T15:02:37"},
        "valid datetime dd-MM-yyyy HH:mm" => {base: "datetime", value: "15-03-2015 15:02", format: "dd-MM-yyyy HH:mm", result: "2015-03-15T15:02:00"},
        "valid datetime d-M-yyyy HHmm"   => {base: "datetime", value: "15-3-2015 1502",  format: "d-M-yyyy HHmm",   result: "2015-03-15T15:02:00"},
        "valid datetime yyyy-MM-ddTHH:mm"   => {base: "datetime", value: "2015-03-15T15:02",  format: "yyyy-MM-ddTHH:mm",   result: "2015-03-15T15:02:00"},

        # Timezones
        "valid w/TZ yyyy-MM-ddX" => {base: "date", value: "2015-03-22Z", format: "yyyy-MM-ddX", result: "2015-03-22Z"},
        "valid w/TZ HH:mm:ssX" => {base: "time", value: "15:02:37-05", format: "HH:mm:ssX", result: "15:02:37-05:00"},
        "valid w/TZ yyyy-MM-dd HH:mm:ss X" => {base: "dateTimeStamp", value: "2015-03-15 15:02:37 +0800", format: "yyyy-MM-dd HH:mm:ss X", result: "2015-03-15T15:02:37+08:00"},
        "valid w/TZ HHmm XX" => {base: "time", value: "1502 +0800", format: "HHmm XX", result: "15:02:00+08:00"},
        "valid w/TZ yyyy-MM-dd HH:mm:ss XX" => {base: "dateTimeStamp", value: "2015-03-15 15:02:37 -0800", format: "yyyy-MM-dd HH:mm:ss XX", result: "2015-03-15T15:02:37-08:00"},
        "valid w/TZ HHmm XXX" => {base: "time", value: "1502 +08:00", format: "HHmm XXX", result: "15:02:00+08:00"},
        "valid w/TZ yyyy-MM-ddTHH:mm:ssXXX" => {base: "dateTime", value: "2015-03-15T15:02:37-05:00", format: "yyyy-MM-ddTHH:mm:ssXXX", result: "2015-03-15T15:02:37-05:00"},
        "invalid w/TZ HH:mm:ssX" => {base: "time", value: "15:02:37-05:00", format: "HH:mm:ssX", errors: ["15:02:37-05:00 does not match format HH:mm:ssX"]},
        "invalid w/TZ HH:mm:ssXX" => {base: "time", value: "15:02:37-05", format: "HH:mm:ssXX", errors: ["15:02:37-05 does not match format HH:mm:ssXX"]},

        # Other date-like things
        "valid gDay" => {base: "gDay", value: "---31"},
        "valid gMonth" => {base: "gMonth", value: "--02"},
        "valid gMonthDay" => {base: "gMonthDay", value: "--02-21"},
        "valid gYear" => {base: "gYear", value: "9999"},
        "valid gYearMonth" => {base: "gYearMonth", value: "1999-05"},

        # Durations
        "valid duration PT130S"    => {base: "duration", value: "PT130S"},
        "valid duration PT130M"    => {base: "duration", value: "PT130M"},
        "valid duration PT130H"    => {base: "duration", value: "PT130H"},
        "valid duration P130D"     => {base: "duration", value: "P130D"},
        "valid duration P130M"     => {base: "duration", value: "P130M"},
        "valid duration P130Y"     => {base: "duration", value: "P130Y"},
        "valid duration PT2M10S"   => {base: "duration", value: "PT2M10S"},
        "valid duration P0Y20M0D"  => {base: "duration", value: "P0Y20M0D"},
        "valid duration -P60D"     => {base: "duration", value: "-P60D"},
        "valid dayTimeDuration P1DT2H"    => {base: "dayTimeDuration", value: "P1DT2H"},
        "valid yearMonthDuration P0Y20M"  => {base: "yearMonthDuration", value: "P0Y20M"},

        # Other datatypes
        "valid anyAtomicType" => {base: "anyAtomicType", value: "some thing", result: RDF::Literal("some thing", datatype: RDF::XSD.anyAtomicType)},
        "valid anyURI" => {base: "anyURI", value: "http://example.com/", result: RDF::Literal("http://example.com/", datatype: RDF::XSD.anyURI)},
        "valid base64Binary" => {base: "base64Binary", value: "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g", result: RDF::Literal("Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g", datatype: RDF::XSD.base64Binary)},
        "base64Binary with matching length:" => {
          base: "base64Binary",
          value: "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g",
          length: 45,
          result: RDF::Literal("Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g", datatype: RDF::XSD.base64Binary)
        },
        "base64Binary with wrong maxLength:" => {
          base: "base64Binary",
          value: "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g",
          maxLength: 1,
          errors: ["decoded Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g has length 45 not <= 1"]
        },
        "base64Binary with wrong minLength" => {
          base: "base64Binary",
          value: "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g",
          minLength: 50,
          errors: ["decoded Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g has length 45 not >= 50"]
        },
        "valid hexBinary" => {base: "hexBinary", value: "0FB7", result: RDF::Literal("0FB7", datatype: RDF::XSD.hexBinary)},
        "hexBinary with matching length:" => {
          base: "hexBinary",
          value: "0FB7",
          length: 2,
          result: RDF::Literal("0FB7", datatype: RDF::XSD.hexBinary)
        },
        "hexBinary with wrong maxLength:" => {
          base: "hexBinary",
          value: "0FB7",
          maxLength: 1,
          errors: ["decoded 0FB7 has length 2 not <= 1"]
        },
        "hexBinary with wrong minLength" => {
          base: "hexBinary",
          value: "0FB7",
          minLength: 4,
          errors: ["decoded 0FB7 has length 2 not >= 4"]
        },
        "valid QName" => {base: "QName", value: "foo:bar", result: RDF::Literal("foo:bar", datatype: RDF::XSD.QName)},
        "valid normalizedString" => {base: "normalizedString", value: "some thing", result: RDF::Literal("some thing", datatype: RDF::XSD.normalizedString)},
        "valid token" => {base: "token", value: "some thing", result: RDF::Literal("some thing", datatype: RDF::XSD.token)},
        "valid language" => {base: "language", value: "en", result: RDF::Literal("en", datatype: RDF::XSD.language)},
        "valid Name" => {base: "Name", value: "someThing", result: RDF::Literal("someThing", datatype: RDF::XSD.Name)},
        "valid NMTOKEN" => {base: "NMTOKEN", value: "someThing", result: RDF::Literal("someThing", datatype: RDF::XSD.NMTOKEN)},

        # Aliases
        "number is alias for double" => {base: "number", value: "1234.456e789", result: RDF::Literal("1234.456e789", datatype: RDF::XSD.double)},
        "binary is alias for base64Binary" => {base: "binary", value: "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g", result: RDF::Literal("Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMKdG8gbGVhcm4g", datatype: RDF::XSD.base64Binary)},
        "datetime is alias for dateTime" => {base: "dateTime", value: "15-3-2015 1502",  format: "d-M-yyyy HHmm", result: RDF::Literal("2015-03-15T15:02:00", datatype: RDF::XSD.dateTime)},
        "any is alias for anyAtomicType" => {base: "any", value: "some thing", result: RDF::Literal("some thing", datatype: RDF::XSD.anyAtomicType)},
        "xml is alias for rdf:XMLLiteral" => {base: "xml", value: "<foo></foo>", result: RDF::Literal("<foo></foo>", datatype: RDF.XMLLiteral)},
        "html is alias for rdf:HTML" => {base: "html", value: "<foo></foo>", result: RDF::Literal("<foo></foo>", datatype: RDF.HTML)},
        #"json is alias for csvw:JSON" => {base: "json", value: %({""foo"": ""bar""}), result: RDF::Literal(%({"foo": "bar"}), datatype: RDF::Tabular::CSVW.json)},
      }.each do |name, props|
        context name do
          let(:value) {props[:value]}
          let(:result) {
            if props[:errors]
              RDF::Literal(props.fetch(:result, value))
            else
              RDF::Literal(props.fetch(:result, value), datatype: md.context.expand_iri(props[:base], vocab: true))
            end
          }
          let(:md) {
            RDF::Tabular::Table.new({
              url: "http://example.com/table.csv",
              dialect: {header: false},
              tableSchema: {
                columns: [{
                  name: "name",
                  datatype: props.dup.delete_if {|k, v| [:value, :valid, :result].include?(k)}
                }]
              }
            }, logger: logger)
          }
          subject {md.to_enum(:each_row, "#{value}\n").to_a.first.values.first}

          if props[:errors]
            it {is_expected.not_to be_valid}
            it "has expected errors" do
              props[:errors].each do |e|
                expect(subject.errors.to_s).to match(e)
              end
            end
          else
            it {is_expected.to be_valid}
            it "has no errors" do
              expect(subject.errors).to be_empty
            end
          end

          specify {expect(subject.value).to eql result}
        end
      end

      context "Unsupported datatypes" do
        %w(anyType anySimpleType ENTITIES IDREFS NMTOKENS ENTITY ID IDREF NOTATAION foo).each do |base|
          it "detects #{base} as unsupported" do
            RDF::Tabular::Table.new({
             url: "http://example.com/table.csv",
              tableSchema: {
                columns: [{
                  name: "name",
                  datatype: base
                }]
              }
            },
            logger: logger)
            expect(subject).to be_valid
            expect(logger.to_s).to include("WARN")
          end
        end
      end
    end
  end

  context "Number formats" do
    {
      '0'          => {valid: %w(1 -1 +1 12), invalid: %w(1.2), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,})(?<suffix>)$/},
      '00'         => {valid: %w(12 123), invalid: %w(1 1,2), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{2,})(?<suffix>)$/},
      '#'          => {valid: %w(1 12 123), invalid: %w(1.2), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{0,})(?<suffix>)$/},
      '##'         => {re: /^(?<prefix>[+-]?)(?<numeric_part>\d{0,})(?<suffix>)$/},
      '#0'         => {re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,})(?<suffix>)$/},

      '0.0'         => {valid: %w(1.1 -1.1 12.1), invalid: %w(1.12), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1})(?<suffix>)$/},
      '0.00'        => {valid: %w(1.12 +1.12 12.12), invalid: %w(1.1 1.123), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{2})(?<suffix>)$/},
      '0.#'         => {valid: %w(1 1.1 12.1), invalid: %w(1.12), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}(?:\.\d{0,1})?)(?<suffix>)$/},
      '-0'         => {valid: %w(-1 -10), invalid: %w(1 +1), base: "decimal", re: /^(?<prefix>\-)(?<numeric_part>\d{1,})(?<suffix>)$/},
      '%000'       => {valid: %w(%123 %+123 %-123 %1234), invalid: %w(%12 123%), base: "decimal", re: /^(?<prefix>%[+-]?)(?<numeric_part>\d{3,})(?<suffix>)$/},
      '‰000'       => {valid: %w(‰123 ‰+123 ‰-123 ‰1234), invalid: %w(‰12 123‰), base: "decimal", re: /^(?<prefix>‰[+-]?)(?<numeric_part>\d{3,})(?<suffix>)$/},
      '000%'       => {valid: %w(123% +123% -123% 1234%), invalid: %w(12% %123), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{3,})(?<suffix>%)$/},
      '000‰'       => {valid: %w(123‰ +123‰ -123‰ 1234‰), invalid: %w(12‰ ‰123), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{3,})(?<suffix>‰)$/},
      '000.0%'     => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{3,}\.\d{1})(?<suffix>%)$/},

      '###0.#####' => {valid: %w(1 1.1 12345.12345), invalid: %w(1,234.1 1.123456), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}(?:\.\d{0,5})?)(?<suffix>)$/},
      '###0.0000#' => {valid: %w(1.1234 1.12345 12345.12345), invalid: %w(1,234.1234 1.12), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{4,5})(?<suffix>)$/},
      '00000.0000' => {valid: %w(12345.1234), invalid: %w(1.2 1,234.123,4), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{5,}\.\d{4})(?<suffix>)$/},

      '#0.0#E#0'   => {base: "double", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1,2}E[+-]?\d{1,2})(?<suffix>)$/},
      '#0.0#E+#0'   => {base: "double", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1,2}E\+\d{1,2})(?<suffix>)$/},
      '#0.0#E#0%'  => {base: "double", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1,2}E[+-]?\d{1,2})(?<suffix>%)$/},

      # Grouping
      '#,##,##0'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d)?\d{1})(?<suffix>)$/},
      '#,##,#00'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d{2})(?<suffix>)$/},
      '#,##,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:\d{1,2},)?(?:\d{2},)*\d{3})(?<suffix>)$/},
      '#,#0,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d{1},\d{3})(?<suffix>)$/},
      '#,00,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:\d{1,2},)?(?:\d{2},)*\d{2},\d{3})(?<suffix>)$/},
      '0,00,000'   => {base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,2},)?(?:\d{2},)*\d)?\d{1},\d{2},\d{3})(?<suffix>)$/},

      '0.0##,###'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1}(?:\d(?:\d(?:,\d(?:\d(?:\d)?)?)?)?)?)(?<suffix>)$/},
      '0.00#,###'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{2}(?:\d(?:,\d(?:\d(?:\d)?)?)?)?)(?<suffix>)$/},
      '0.000,###'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3}(?:,\d(?:\d(?:\d)?)?)?)(?<suffix>)$/},
      '0.000,0##'  => {base: "decimal", re:/^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3},\d{1}(?:\d(?:\d)?)?)(?<suffix>)$/},
      '0.000,00#'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3},\d{2}(?:\d)?)(?<suffix>)$/},
      '0.000,000'  => {base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{3},\d{3})(?<suffix>)$/},

      # Jeni's
      '##0'        => {valid: %w(1 12 123 1234), invalid: %w(1,234 123.4), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,})(?<suffix>)$/},
      '#,#00'      => {valid: %w(12 123 1,234 1,234,567), invalid: %w(1 1234 12,34 12,34,567), base: "integer", re: /^(?<prefix>[+-]?)(?<numeric_part>(?:(?:\d{1,3},)?(?:\d{3},)*\d)?\d{2})(?<suffix>)$/},
      '#0.#'       => {valid: %w(1 1.2 1234.5), invalid: %w(12.34 1,234.5), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}(?:\.\d{0,1})?)(?<suffix>)$/},
      '#0.0#,#'    => {valid: %w(12.3 12.34 12.34,5), invalid: %w(1 12.345 12.34,56,7 12.34,567), base: "decimal", re: /^(?<prefix>[+-]?)(?<numeric_part>\d{1,}\.\d{1}(?:\d(?:,\d)?)?)(?<suffix>)$/},
    }.each do |pattern, props|
      context pattern do
        subject {RDF::Tabular::Datatype.new({})}
        describe "#build_number_re" do
          it "generates #{props[:re]} for #{pattern}" do
            expect(subject.build_number_re(pattern, ",", ".")).to eql props[:re]
          end if props[:re].is_a?(Regexp)

          it "recognizes bad pattern #{pattern}" do
            expect{subject.build_number_re(pattern, ",", ".")}.to raise_error(ArgumentError)
          end if props[:re] == ArgumentError
        end

        describe "Metadata" do
          let(:md) {
            RDF::Tabular::Table.new({
              url: "http://example.com/table.csv",
              dialect: {header: false},
              tableSchema: {
                columns: [{
                  name: "name",
                  datatype: {"base" => props[:base], "format" => {"pattern" => pattern}}
                }]
              }
            }, logger: logger)
          }
          describe "valid" do
            Array(props[:valid]).each do |num|
              it "for #{num}" do
                cell = md.to_enum(:each_row, "\"#{num}\"\n").to_a.first.values.first
                expect(cell).to be_valid
              end
            end
          end
          describe "invalid" do
            Array(props[:invalid]).each do |num|
              it "for #{num}" do
                cell = md.to_enum(:each_row, "\"#{num}\"\n").to_a.first.values.first
                expect(cell).not_to be_valid
              end
            end
          end
        end
      end
    end
  end

  describe "#common_properties" do
    describe "#normalize!" do
      {
        "string with no language" => [
          %({
            "@context": "http://www.w3.org/ns/csvw",
            "dc:title": "foo"
          }),
          %({
            "@context": "http://www.w3.org/ns/csvw",
            "dc:title": {"@value": "foo"}
          })
        ],
        "string with language" => [
          %({
            "@context": ["http://www.w3.org/ns/csvw", {"@language": "en"}],
            "dc:title": "foo"
          }),
          %({
            "@context": "http://www.w3.org/ns/csvw",
            "dc:title": {"@value": "foo", "@language": "en"}
          })
        ],
        "relative URL" => [
          %({
            "@context": "http://www.w3.org/ns/csvw",
            "dc:source": {"@id": "foo"}
          }),
          %({
            "@context": "http://www.w3.org/ns/csvw",
            "dc:source": {"@id": "http://example.com/foo"}
          })
        ],
        "array of values" => [
          %({
            "@context": ["http://www.w3.org/ns/csvw", {"@language": "en"}],
            "dc:title": [
              "foo",
              {"@value": "bar"},
              {"@value": "baz", "@language": "de"},
              1,
              true,
              {"@value": 1},
              {"@value": true},
              {"@value": "1", "@type": "xsd:integer"},
              {"@id": "foo"}
            ]
          }),
          %({
            "@context": "http://www.w3.org/ns/csvw",
            "dc:title": [
              {"@value": "foo", "@language": "en"},
              {"@value": "bar"},
              {"@value": "baz", "@language": "de"},
              1,
              true,
              {"@value": 1},
              {"@value": true},
              {"@value": "1", "@type": "xsd:integer"},
              {"@id": "http://example.com/foo"}
            ]
          })
        ],
      }.each do |name, (input, result)|
        it name do
          a = RDF::Tabular::Table.new(input, base: "http://example.com/A", logger: logger)
          b = RDF::Tabular::Table.new(result, base: "http://example.com/A", logger: logger)
          expect(a.normalize!).to eq b
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        end
      end
    end

    context "transformation" do
      it "FIXME"
    end
  end

  describe "#verify_compatible!" do
    {
      "two tables with same id" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table",
          "tableSchema": {"columns": []}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table",
          "tableSchema": {"columns": []}
        }),
        R: true
      },
      "two tables with different id" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": []}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table2",
          "tableSchema": {"columns": []}
        }),
        R: false
      },
      "table-group and table with same url" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "TableGroup",
          "tables": [{
            "@type": "Table",
            "url": "http://example.org/table1",
            "tableSchema": {"columns": []}
          }]
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": []}
        }),
        R: true
      },
      "table-group and table with different url" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "TableGroup",
          "tables": [{
            "@type": "Table",
            "url": "http://example.org/table1",
            "tableSchema": {"columns": []}
          }]
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table2",
          "tableSchema": {"columns": []}
        }),
        R: false
      },
      "table-group with two tables" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "TableGroup",
          "tables": [{
            "@type": "Table",
            "url": "http://example.org/table1",
            "tableSchema": {"columns": []}
          }, {
            "@type": "Table",
            "url": "http://example.org/table2",
            "tableSchema": {"columns": []}
          }]
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table2",
          "tableSchema": {"columns": []}
        }),
        R: true
      },
      "tables with matching columns" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}]}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}]}
        }),
        R: true
      },
      "tables with virtual columns otherwise matching" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}, {"virtual": true}]}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}]}
        }),
        R: true
      },
      "tables with differing columns" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}]}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "bar"}]}
        }),
        R: false
      },
      "tables with different column count" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}, {"name": "bar"}]}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "bar"}]}
        }),
        R: false
      },
      "tables with matching columns on name/titles" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}]}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"titles": "foo"}]}
        }),
        R: false
      },
      "tables with mismatch columns on name/titles" => {
        A: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"name": "foo"}]}
        }),
        B: %({
          "@context": "http://www.w3.org/ns/csvw",
          "@type": "Table",
          "url": "http://example.org/table1",
          "tableSchema": {"columns": [{"titles": "bar"}]}
        }),
        R: false
      },
    }.each do |name, props|
      it name do
        a = described_class.new(::JSON.parse(props[:A]), validate: true)
        b = described_class.new(::JSON.parse(props[:B]))
        if props[:R]
          expect {a.verify_compatible!(b)}.not_to raise_error
          expect(logger.to_s).not_to match(/ERROR|WARN/)
        else
          expect {a.verify_compatible!(b)}.to raise_error(RDF::Tabular::Error)
        end
      end
    end
  end
end
