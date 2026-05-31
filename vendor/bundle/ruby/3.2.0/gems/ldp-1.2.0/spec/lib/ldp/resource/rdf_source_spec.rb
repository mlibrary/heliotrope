require 'stringio'
require 'spec_helper'
require 'rdf/vocab/dc'

describe Ldp::Resource::RdfSource do
  let(:simple_graph) do
    RDF::Graph.new << [RDF::URI.new(), RDF::Vocab::DC.title, "Hello, world!"]
  end

  let(:simple_graph_source) do
    io = StringIO.new
    RDF::Writer.for(content_type:'text/turtle').dump(simple_graph,io)
    io.string
  end
  let(:conn_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/") { [201]}
      stub.put("/abs_url_object") { [201]}
      stub.head("/abs_url_object") {[404]}
      stub.get("/abs_url_object") {[404]}
      stub.head("/existing_object") {[200, {'Content-Type'=>'text/turtle'}]}
      stub.get("/existing_object") {[200, {'Content-Type'=>'text/turtle'}, simple_graph_source]}
    end
  end

  let(:mock_conn) do
    Faraday.new url: "http://my.ldp.server/" do |builder|
      builder.adapter :test, conn_stubs do |stub|
      end
    end
  end

  let :mock_client do
    Ldp::Client.new mock_conn
  end


  describe "#create" do
    subject { rdf_source }
    let(:rdf_source) { Ldp::Resource::RdfSource.new mock_client, nil }

    context "if the resource already exists" do
      subject { rdf_source.create }
      before do
        allow(rdf_source).to receive(:new?).and_return(false)
      end
      it "raises an error" do
        expect { subject }.to raise_error Ldp::Conflict
      end
    end

    it "should return a new resource" do
      created_resource = subject.create
      expect(created_resource).to be_kind_of Ldp::Resource::RdfSource
    end

    it "should allow absolute URLs to the LDP server" do
      obj = Ldp::Resource::RdfSource.new mock_client, "http://my.ldp.server/abs_url_object"
      created_resource = obj.create
      expect(created_resource).to be_kind_of Ldp::Resource::RdfSource
    end

    describe 'basic containers' do
      it 'sends the requested interaction model' do
        obj = Ldp::Container::Basic.new mock_client, "http://my.ldp.server/abs_url_object"
        created_resource = obj.create
        expect(created_resource).to be_kind_of Ldp::Container::Basic
      end
    end

    describe 'direct containers' do
      it 'sends the requested interaction model' do
        obj = Ldp::Container::Direct.new mock_client, "http://my.ldp.server/abs_url_object"
        created_resource = obj.create
        expect(created_resource).to be_kind_of Ldp::Container::Direct
      end
    end

    describe 'indirect containers' do
      it 'sends the requested interaction model' do
        obj = Ldp::Container::Indirect.new mock_client, "http://my.ldp.server/abs_url_object"
        created_resource = obj.create
        expect(created_resource).to be_kind_of Ldp::Container::Indirect
      end
    end
  end

  describe "#initialize" do
    context "with bad attributes" do
      it "should raise an error" do
        expect{ Ldp::Resource::RdfSource.new mock_client, nil, "derp" }.to raise_error(ArgumentError,
          "Third argument to Ldp::Resource::RdfSource.new should be a RDF::Enumerable or a Ldp::Response. You provided String")
      end
    end
  end

  describe '#graph' do
    context 'for a new object' do
      subject { Ldp::Resource::RdfSource.new mock_client, nil }
      it do
        expect(subject.graph.size).to eql(0)
      end
    end
    context 'for an existing object' do
      subject { Ldp::Resource::RdfSource.new mock_client, "http://my.ldp.server/existing_object" }
      it do
        expect(subject.graph.size).to eql(1)
      end
    end

    context 'with inlined resources' do
      subject { Ldp::Resource::RdfSource.new mock_client, "http://my.ldp.server/existing_object" }

      let(:simple_graph) do
        graph = RDF::Graph.new
        graph << [RDF::URI.new(), RDF::Vocab::DC.title, "Hello, world!"]
        graph << [RDF::URI.new(), RDF::Vocab::LDP.contains, contained_uri]
        graph << [contained_uri, RDF::Vocab::DC.title, "delete me"]
      end

      let(:contained_uri) { RDF::URI.new('http://example.com/contained') }

      it do
        expect(subject.graph.subjects)
          .to contain_exactly(RDF::URI('http://my.ldp.server/existing_object'))
      end
    end
  end

  context "When graph_class is overridden" do
    before do
      class SpecialGraph < RDF::Graph; end

      class SpecialResource < Ldp::Resource::RdfSource
        def graph_class
          SpecialGraph
        end
      end
    end

    after do
      Object.send(:remove_const, :SpecialGraph)
      Object.send(:remove_const, :SpecialResource)
    end

    subject { SpecialResource.new mock_client, nil }

    it "should use the specified class" do
      expect(subject.graph).to be_a SpecialGraph
    end

    context "with a response body" do
      subject { SpecialResource.new mock_client, "http://my.ldp.server/existing_object" }


      it "should use the specified class" do
        expect(subject.graph).to be_a SpecialGraph
      end
    end
  end
end
