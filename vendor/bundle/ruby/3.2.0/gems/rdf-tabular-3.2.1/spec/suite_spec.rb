$:.unshift "."
require 'spec_helper'
require 'fileutils'

WebMock.allow_net_connect!(net_http_connect_on_start: true)
describe RDF::Tabular::Reader do
  require 'suite_helper'

  before(:all) {WebMock.allow_net_connect!(net_http_connect_on_start: true)}
  after(:all) {WebMock.allow_net_connect!(net_http_connect_on_start: false)}

  %w(rdf json validation nonnorm).each do |variant|
    describe "w3c csvw #{variant.upcase} tests" do
      manifest = Fixtures::SuiteTest::BASE + "manifest-#{variant}.jsonld"

      Fixtures::SuiteTest::Manifest.open(manifest, manifest[0..-8]) do |m|
        describe m.comment do
          m.entries.each do |t|
            next if t.approval =~ /Rejected/
            specify "#{t.id.split("/").last}: #{t.name} - #{t.comment}" do
              pending "rdf#test283 literal normalization" if t.id.include?("rdf#test283")
              t.logger = RDF::Spec.logger
              t.logger.formatter = lambda {|severity, datetime, progname, msg| "#{severity}: #{msg}\n"}
              t.logger.info t.inspect
              t.logger.info "source:\n#{t.input}"
              begin
                RDF::Tabular::Reader.open(t.action,
                  base_uri: t.base,
                  validate: t.validation?,
                  logger:   t.logger,
                  **t.reader_options
                ) do |reader|
                  expect(reader).to be_a RDF::Reader

                  t.metadata = reader.metadata # for debug output
                  t.metadata = t.metadata.parent if t.metadata && t.metadata.parent

                  graph = RDF::Repository.new

                  if t.positive_test?
                    if t.json?
                      result = reader.to_json
                      if t.evaluate?
                        RDF::Util::File.open_file(t.result) do |res|
                          expect(::JSON.parse(result)).to produce(::JSON.parse(res.read), t)
                        end
                      else
                        expect(::JSON.parse(result)).to be_a(Hash)
                      end
                    else # RDF or Validation
                      if t.evaluate?
                        graph << reader
                        output_graph = RDF::Repository.load(t.result, format: :ttl, base_uri:  t.base)
                        expect(graph).to be_equivalent_graph(output_graph, t)
                      elsif t.validation?
                        expect {reader.validate!}.not_to raise_error
                      end
                    end

                    if t.warning?
                      expect(t.logger.log_statistics).to have_key(:warn)
                    else
                      expect(t.logger.log_statistics).not_to have_key(:warn)
                    end
                    expect(t.logger.log_statistics).not_to have_key(:error)
                  elsif t.json?
                    expect {reader.to_json}.to raise_error(RDF::Tabular::Error)
                  elsif t.validation?
                    expect {reader.validate!}.to raise_error(RDF::Tabular::Error)
                  else
                    expect {graph << reader}.to raise_error(RDF::ReaderError)
                  end
                end
              rescue IOError
                # Special case when Reader.initialize raises the error
                raise unless t.negative_test?
              end
            end
          end
        end
      end
    end
  end
end unless ENV['CI']  # Skip for continuous integration