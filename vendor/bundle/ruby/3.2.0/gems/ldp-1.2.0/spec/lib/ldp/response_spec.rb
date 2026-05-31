require 'spec_helper'

describe Ldp::Response do
  LDP_RDF_RESOURCE_HEADERS = { "Link" => "<#{RDF::Vocab::LDP.Resource}>;rel=\"type\", <#{RDF::Vocab::LDP.DirectContainer}>;rel=\"type\""}
  LDP_NON_RDF_SOURCE_HEADERS = { "Link" => "<#{RDF::Vocab::LDP.Resource}>;rel=\"type\", <#{RDF::Vocab::LDP.NonRDFSource}>;rel=\"type\""}

  let(:mock_response) { instance_double(Faraday::Response, headers: {}, env: { url: "info:a" }) }
  let(:mock_client) { instance_double(Ldp::Client) }

  subject do
    Ldp::Response.new mock_response
  end

  describe "#dup" do
    let(:mock_conn) { Faraday.new { |builder| builder.adapter :test, conn_stubs } }
    let(:client) { Ldp::Client.new mock_conn }
    let(:conn_stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/a_container') { [200, {"Link" => link}, body] }
      end
    end
    let(:response) { client.get "a_container" }

    subject { response.dup }

    context "for a container resource" do
      let(:body) { "<> a <http://www.w3.org/ns/ldp#Container> ." }
      let(:link) { ["<http://www.w3.org/ns/ldp#Resource>;rel=\"type\"","<http://www.w3.org/ns/ldp#BasicContainer>;rel=\"type\""] }
      it { is_expected.to respond_to :links }

      it "should not have duplicated the graph" do
        expect(response.graph.object_id).not_to eq subject.graph.object_id
      end

      it "should have duplicated the body" do
        expect(response.body.object_id).to eq subject.body.object_id
      end
    end

    context "for a non-rdf resource" do
      let(:body) { "This is only a test" }
      let(:link) { ["<http://www.w3.org/ns/ldp#Resource>;rel=\"type\"","<http://www.w3.org/ns/ldp#NonRDFSource>;rel=\"type\""] }
      it { is_expected.to respond_to :links }

      it "should not have a graph" do
        expect(response.instance_variable_get(:@graph)).to be_nil
      end

      it "should have duplicated the body" do
        expect(response.body.object_id).to eq subject.body.object_id
      end
    end
  end


  describe "#links" do
    it "should extract link headers with relations as a hash" do
      allow(mock_response).to receive(:headers).and_return(
        "Link" => [
            "<xyz>;rel=\"some-rel\"",
            "<abc>;rel=\"some-multi-rel\"",
            "<123>;rel=\"some-multi-rel\"",
            "<vanilla-link>"
          ]
        )
      h = subject.links

      expect(h['some-rel']).to include("xyz")
      expect(h['some-multi-rel']).to include("abc", "123")
      expect(h['doesnt-exist']).to be_nil
    end

    it "should return an empty hash if no link headers are availabe" do
      allow(mock_response).to receive(:headers).and_return({})
      h = subject.links

      expect(h).to be_empty
    end

  end

  describe "#resource?" do
    it "should be a resource if a Link[rel=type] header asserts it is an ldp:resource" do
      allow(mock_response).to receive(:headers).and_return(
        "Link" => [
            "<#{RDF::Vocab::LDP.Resource}>;rel=\"type\""
          ]
        )
      expect(subject.resource?).to be true
    end
  end

  describe "#graph" do
    context "for an RDFSource (or Container)" do
      it "should parse the response body for an RDF graph" do
        allow(mock_response).to receive(:body).and_return("<> <info:b> <info:c> .")
        allow(mock_response).to receive(:headers).and_return(LDP_RDF_RESOURCE_HEADERS)
        graph = subject.graph

        expect(graph).to have_subject(RDF::URI.new("info:a"))
        expect(graph).to have_statement RDF::Statement.new(RDF::URI.new("info:a"), RDF::URI.new("info:b"), RDF::URI.new("info:c"))
      end
    end
  end

  describe "#etag" do
    it "should pass through the response's ETag" do
      allow(mock_response).to receive(:headers).and_return('ETag' => 'xyz')

      expect(subject.etag).to eq('xyz')
    end
  end

  describe "#last_modified" do
    it "should pass through the response's Last-Modified" do
      allow(mock_response).to receive(:headers).and_return('Last-Modified' => 'some-date')
      expect(subject.last_modified).to eq('some-date')
    end
  end

  describe "#has_page?" do
    context "for an RDF Source" do
      before do
        allow(mock_response).to receive(:headers).and_return(LDP_RDF_RESOURCE_HEADERS)
      end

      it "should see if the response has an ldp:Page statement" do
        graph = RDF::Graph.new
        graph << [RDF::URI.new('info:a'), RDF.type, RDF::Vocab::LDP.Page]
        allow(mock_response).to receive(:body).and_return(graph.dump(:ttl))
        expect(subject).to have_page
      end

      it "should be false otherwise" do
        # allow(subject).to receive(:page_subject).and_return RDF::URI.new('info:a')
        graph = RDF::Graph.new
        allow(mock_response).to receive(:body).and_return(graph.dump(:ttl))
        expect(subject).not_to have_page
      end
    end

    context "with a non-rdf-source" do
      it "should be false" do
        # allow(subject).to receive(:page_subject).and_return RDF::URI.new('info:a')
        # allow(mock_response).to receive(:body).and_return('')
        allow(mock_response).to receive(:headers).and_return(LDP_NON_RDF_SOURCE_HEADERS)
        expect(subject).not_to have_page
      end
    end
  end

  describe "#page" do
    it "should get the ldp:Page data from the query" do
      graph = RDF::Graph.new

      graph << [RDF::URI.new('info:a'), RDF.type, RDF::Vocab::LDP.Page]
      graph << [RDF::URI.new('info:b'), RDF.type, RDF::Vocab::LDP.Page]

      allow(mock_response).to receive(:body).and_return(graph.dump(:ttl))
      allow(mock_response).to receive(:headers).and_return(LDP_RDF_RESOURCE_HEADERS)

      expect(subject.page.count).to eq(1)
    end
  end

  describe "#subject" do
    it "should extract the HTTP request URI as an RDF URI" do
      allow(mock_response).to receive(:body).and_return('')
      allow(mock_response).to receive(:headers).and_return(LDP_RDF_RESOURCE_HEADERS)
      allow(mock_response).to receive(:env).and_return(:url => 'http://xyz/a')
      expect(subject.subject).to eq(RDF::URI.new("http://xyz/a"))
    end
  end

  describe '#content_type' do
    before do
      allow(mock_response).to receive(:headers).and_return(
        'Content-Type' => 'application/octet-stream'
      )
    end

    it 'provides the content type from the response' do
      expect(subject.content_type).to eq 'application/octet-stream'
    end
  end

  describe '#content_length' do
    before do
      allow(mock_response).to receive(:headers).and_return(
        'Content-Length' => '123'
      )
    end

    it 'provides the content length from the response' do
      expect(subject.content_length).to eq 123
    end
  end

  describe '#content_disposition_filename' do
    before do
      allow(mock_response).to receive(:headers).and_return(
        { 'Content-Disposition' => 'filename="xyz.txt";' },
        { 'Content-Disposition' => 'attachment; filename=xyz.txt' },
        { 'Content-Disposition' => 'attachment; filename="xyz.txt"; size="12345"' },
        { 'Content-Disposition' => 'attachment; filename=""; size="12345"' },
      )
    end

    it 'provides the filename from the content disposition header' do
      3.times { expect(subject.content_disposition_filename).to eq 'xyz.txt' }
      expect(subject.content_disposition_filename).to eq ''
    end
  end
end
