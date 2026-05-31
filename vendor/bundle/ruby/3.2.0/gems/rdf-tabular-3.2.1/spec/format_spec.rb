# coding: utf-8
$:.unshift "."
require 'spec_helper'
require 'rdf/spec/format'

describe RDF::Tabular::Format do
  it_behaves_like 'an RDF::Format' do
    let(:format_class) {RDF::Tabular::Format}
  end

  describe ".for" do
    formats = [
      :tabular,
      'etc/doap.csv',
      'etc/doap.tsv',
      {file_name:      'etc/doap.csv'},
      {file_name:      'etc/doap.tsv'},
      {file_extension: 'csv'},
      {file_extension: 'tsv'},
      {content_type:   'text/csv'},
      {content_type:   'text/tab-separated-values'},
      {content_type:   'application/csvm+json'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Tabular::Format).to include RDF::Format.for(arg)
      end
    end
  end

  describe "#to_sym" do
    specify {expect(described_class.to_sym).to eq :tabular}
  end

  describe ".cli_commands", skip: ("TextMate OptionParser issues" if ENV['TM_SELECTED_FILE']) do
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

    require 'rdf/cli'
    let(:input) {"http://example.org/data/countries.json"}
    describe "#tabular-json" do
      it "serializes to JSON" do
        expect {
          RDF::CLI.exec(["tabular-json", input], format: :tabular)
      }.to write.to(:output)
      end
    end
  end
end
