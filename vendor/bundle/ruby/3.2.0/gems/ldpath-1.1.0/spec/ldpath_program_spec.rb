require 'spec_helper'

describe Ldpath::Program do
  describe "Simple program" do
    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
parent_title = dcterms:isPartOf / dcterms:title :: xsd:string ;
parent_title_en = dcterms:isPartOf / dcterms:title[@en] :: xsd:string ;
titles = dcterms:title | (dcterms:isPartOf / dcterms:title) | (^dcterms:isPartOf / dcterms:title) :: xsd:string ;
no_titles = dcterms:title & (dcterms:isPartOf / dcterms:title) & (^dcterms:isPartOf / dcterms:title) :: xsd:string ;
self = . :: xsd:string ;
wildcard = * ::xsd:string ;
child_title = ^dcterms:isPartOf / dcterms:title :: xsd:string ;
child_description_en = ^dcterms:isPartOf / dcterms:description[@en] :: xsd:string ;
recursive = (dcterms:isPartOf)* ;
en_description = dcterms:description[@en] ;
conditional = dcterms:isPartOf[dcterms:title] ;
conditional_false = dcterms:isPartOf[dcterms:description] ;
int_value = <info:intProperty>[^^xsd:integer] :: xsd:integer ;
numeric_value = <info:numericProperty> :: xsd:integer ;
escaped_string = "\\"" :: xsd:string;
and_test = .[dcterms:title & dcterms:gone] ;
or_test = .[dcterms:title | dcterms:gone] ;
is_test = .[dcterms:title is "Hello, world!"] ;
is_not_test = .[!(dcterms:title is "Hello, world!")] ;
EOF
    end

    let(:object) { RDF::URI.new("info:a") }
    let(:parent) { RDF::URI.new("info:b") }
    let(:child) { RDF::URI.new("info:c") }
    let(:grandparent) { RDF::URI.new("info:d") }

    let(:graph) do
      RDF::Graph.new
    end

    it "should work" do
      graph << [object, RDF::Vocab::DC.title, "Hello, world!"]
      graph << [object, RDF::Vocab::DC.isPartOf, parent]
      graph << [object, RDF::Vocab::DC.description, RDF::Literal.new("English!", language: "en")]
      graph << [object, RDF::Vocab::DC.description, RDF::Literal.new("French!", language: "fr")]
      graph << [object, RDF::URI.new("info:intProperty"), 1]
      graph << [object, RDF::URI.new("info:intProperty"), "garbage"]
      graph << [object, RDF::URI.new("info:numericProperty"), "1"]
      graph << [parent, RDF::Vocab::DC.title, "Parent title"]
      graph << [child, RDF::Vocab::DC.isPartOf, object]
      graph << [child, RDF::Vocab::DC.title, "Child title"]
      graph << [parent, RDF::Vocab::DC.title, RDF::Literal.new("Parent English!", language: "en")]
      graph << [parent, RDF::Vocab::DC.title, RDF::Literal.new("Parent French!", language: "fr")]
      graph << [parent, RDF::Vocab::DC.isPartOf, grandparent]

      result = subject.evaluate object, context: graph
      expect(result["title"]).to match_array "Hello, world!"
      expect(result["parent_title"]).to match_array ["Parent title", "Parent English!", "Parent French!"]
      expect(result["parent_title_en"]).to match_array "Parent English!"
      expect(result["self"]).to match_array(object)
      expect(result["wildcard"]).to include "Hello, world!", parent
      expect(result["child_title"]).to match_array "Child title"
      expect(result["titles"]).to match_array ["Hello, world!", "Parent title", "Child title", "Parent English!", "Parent French!"]
      expect(result["no_titles"]).to be_empty
      expect(result["recursive"]).to match_array [parent, grandparent]
      expect(result["en_description"].first.to_s).to eq "English!"
      expect(result["conditional"]).to match_array parent
      expect(result["conditional_false"]).to be_empty
      expect(result["int_value"]).to match_array 1
      expect(result["numeric_value"]).to match_array 1
      expect(result["escaped_string"]).to match_array '\"'
      expect(result["and_test"]).to be_empty
      expect(result["or_test"]).to match_array(object)
      expect(result["is_test"]).to match_array(object)
      expect(result["is_not_test"]).to be_empty
    end
  end

  describe "functions" do
    let(:program) do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
ab = fn:concat("a", "b") ;
title = fn:concat(dcterms:title, dcterms:description) ;
title_mix = fn:concat("!", dcterms:title) ;
title_missing = fn:concat("z", dcterms:genre) ;
first_a = fn:first("a", "b") ;
first_b = fn:first(dcterms:genre, "b") ;
last_a = fn:last("a", dcterms:genre) ;
last_b = fn:last("a", "b") ;
count_5 = fn:count("a", "b", "c", "d", "e");
count_3 = fn:count(dcterms:hasPart);
count_still_3 = fn:count(dcterms:hasPart, dcterms:genre);
eq_true = fn:eq("a", "a");
eq_false = fn:eq("a", "b");
eq_node_true = fn:eq(dcterms:description, "Description");
xpath_test = fn:xpath("//title", "<root><title>xyz</title></root>");
EOF
    end

    let(:object) { RDF::URI.new("info:a") }

    let(:graph) do
      graph = RDF::Graph.new
      graph << [object, RDF::Vocab::DC.title, "Hello, world!"]
      graph << [object, RDF::Vocab::DC.description, "Description"]
      graph << [object, RDF::Vocab::DC.hasPart, "a"]
      graph << [object, RDF::Vocab::DC.hasPart, "b"]
      graph << [object, RDF::Vocab::DC.hasPart, "c"]

      graph
    end

    subject do
      program.evaluate object, context: graph
    end

    describe "concat" do
      it "should concatenate simple string arguments" do
        expect(subject).to include "ab" => ["ab"]
      end

      it "should concatenate node values" do
        expect(subject).to include "title" => ["Hello, world!Description"]
      end

      it "should allow a mixture of string and node values" do
        expect(subject).to include "title_mix" => ["!Hello, world!"]
      end

      it "should ignore missing node values" do
        expect(subject).to include "title_missing" => ["z"]
      end
    end

    describe "first" do
      it "should take the first value" do
        expect(subject).to include "first_a" => ["a"]
      end

      it "should skip missing values" do
        expect(subject).to include "first_b" => ["b"]
      end
    end

    describe "last" do
      it "should take the last value" do
        expect(subject).to include "last_b" => ["b"]
      end

      it "should skip missing values" do
        expect(subject).to include "last_a" => ["a"]
      end
    end

    describe "count" do
      it "should return the number of arguments" do
        expect(subject).to include "count_5" => [5]
      end

      it "should count the number of values for nodes" do
        expect(subject).to include "count_3" => [3]
      end

      it "should skip missing nodes" do
        expect(subject).to include "count_still_3" => [3]
      end
    end

    describe "eq" do
      it "checks if the arguments match" do
        expect(subject).to include "eq_true" => [true]
      end

      it "checks if the arguments fail to match" do
        expect(subject).to include "eq_false" => [false]
      end

      it "checks node values" do
        expect(subject).to include "eq_node_true" => [true]
      end
    end

    describe "xpath" do
      it "evaluates xpath queries against the string contents" do
        expect(subject).to include "xpath_test" => ["xyz"]
      end
    end
  end

  describe "Data loading" do
    subject do
      Ldpath::Program.parse <<-EOF, context
        @prefix dcterms : <http://purl.org/dc/terms/> ;
        title = foaf:primaryTopic / dc:title :: xsd:string ;
        EOF
    end
    let(:context) { {} }

    context 'with direct loading' do
      let(:context) { { default_loader: Ldpath::Loaders::Direct.new }}

      before do
        stub_request(:get, 'http://www.bbc.co.uk/programmes/b0081dq5')
            .to_return(status: 200, body: webmock_fixture('bbc_b0081dq5.nt'), headers: { 'Content-Type' => 'application/n-triples' })
      end

      it "should work" do
        result = subject.evaluate RDF::URI.new("http://www.bbc.co.uk/programmes/b0081dq5")
        expect(result["title"]).to match_array "Huw Stephens"
      end
    end

    context 'with an existing graph' do
      let(:graph) { RDF::Graph.new }
      let(:graph_loader) { Ldpath::Loaders::Graph.new graph: graph }
      let(:context) { { default_loader: graph_loader }}

      before do
        graph << [RDF::URI('http://www.bbc.co.uk/programmes/b0081dq5'), RDF::URI('http://xmlns.com/foaf/0.1/primaryTopic'), RDF::URI('info:some_uri')]
        graph << [RDF::URI('info:some_uri'), RDF::URI('http://purl.org/dc/elements/1.1/title'), 'Local Huw Stephens']
      end

      it "should work" do
        result = subject.evaluate RDF::URI.new("http://www.bbc.co.uk/programmes/b0081dq5")
        expect(result["title"]).to match_array "Local Huw Stephens"
      end
    end

    context 'with linked data fragments' do
      let(:graph_loader) { Ldpath::Loaders::LinkedDataFragment.new('http://example.com/ldf') }
      let(:context) { { default_loader: graph_loader }}

      before do
        stub_request(:get, 'http://example.com/ldf?subject=http://www.bbc.co.uk/programmes/b0081dq5')
            .to_return(status: 200, body: webmock_fixture('bbc_b0081dq5.nt'), headers: { 'Content-Type' => 'application/n-triples' })
      end

      it "should work" do
        result = subject.evaluate RDF::URI.new("http://www.bbc.co.uk/programmes/b0081dq5")
        expect(result["title"]).to match_array "Huw Stephens"
      end
    end
  end

  describe "Predicate function" do
    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
predicates = <http://xmlns.com/foaf/0.1/primaryTopic> / fn:predicates() :: xsd:string ;
EOF
    end

    before do
      stub_request(:get, 'http://www.bbc.co.uk/programmes/b0081dq5')
        .to_return(status: 200, body: webmock_fixture('bbc_b0081dq5.nt'), headers: { 'Content-Type' => 'application/n-triples' })
    end

    it "should work" do
      result = subject.evaluate RDF::URI.new("http://www.bbc.co.uk/programmes/b0081dq5")
      expect(result["predicates"]).to include "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
                                              "http://purl.org/ontology/po/pid",
                                              "http://purl.org/dc/elements/1.1/title"
    end
  end

  describe "tap selector" do
    let(:object) { RDF::URI.new("info:a") }
    let(:child) { RDF::URI.new("info:b") }
    let(:grandchild) { RDF::URI.new("info:c") }

    let(:graph) do
      graph = RDF::Graph.new

      graph << [object, RDF::Vocab::DC.title, "Object"]
      graph << [child, RDF::Vocab::DC.title, "Child"]
      graph << [object, RDF::Vocab::DC.hasPart, child]

      graph
    end

    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
title = dcterms:title :: xsd:string ;
child_title = dcterms:hasPart / dcterms:title :: xsd:string ;
child_title_with_tap = dcterms:hasPart / ?<tap>fn:predicates() / dcterms:title :: xsd:string ;
      EOF
    end

    it "should work" do
      result = subject.evaluate object, context: graph
      expect(result["child_title_with_tap"]).to eq result["child_title"]
      expect(result["tap"]).to eq ["http://purl.org/dc/terms/title"]
    end
  end

  describe "loose selector" do
    let(:object) { RDF::URI.new("info:a") }
    let(:child) { RDF::URI.new("info:b") }
    let(:grandchild) { RDF::URI.new("info:c") }

    let(:graph) do
      graph = RDF::Graph.new

      graph << [object, RDF::Vocab::DC.title, "Object"]
      graph << [child, RDF::Vocab::DC.title, "Child"]
      graph << [object, RDF::Vocab::DC.hasPart, child]

      graph
    end

    subject do
      Ldpath::Program.parse <<-EOF
@prefix dcterms : <http://purl.org/dc/terms/> ;
@prefix dc: <http://purl.org/dc/elements/1.1/> ;
title = dcterms:title :: xsd:string ;
title_with_loose =  ~dc:title :: xsd:string ;
      EOF
    end

    it "should work" do
      result = subject.evaluate object, context: graph
      expect(result["title_with_loose"]).to eq result["title"]
    end
  end

  describe "filter" do
    subject do
      Ldpath::Program.parse <<-EOF
    @prefix dcterms : <http://purl.org/dc/terms/> ;
    @prefix dc: <http://purl.org/dc/elements/1.1/> ;
    @filter is-a dcterms:Agent ;
    title = dcterms:title :: xsd:string ;
      EOF
    end

    let(:object) { RDF::URI.new("info:a") }
    let(:other_object) { RDF::URI.new("info:b") }

    let(:graph) do
      graph = RDF::Graph.new

      graph << [object, RDF.type, RDF::Vocab::DC.Agent]
      graph << [object, RDF::Vocab::DC.title, "Title"]
      graph << [other_object, RDF::Vocab::DC.title, "Other Title"]

      graph
    end

    it "should work" do
      result = subject.evaluate object, context: graph
      expect(result["title"]).to eq ["Title"]
    end

    it "filters objects that don't match" do
      result = subject.evaluate other_object, context: graph
      expect(result).to be_empty
    end
  end

  describe "error handling" do
    it "should provide a reasonable exception" do
      expect { Ldpath::Program.parse "title .= <oops> ;" }.to raise_error(/Expected "=", but got "."/)
    end
  end

  describe '#evaluate' do
    context 'when passing limit_to_context' do
      subject do
        Ldpath::Program.parse <<-EOF
@prefix madsrdf : <http://www.loc.gov/mads/rdf/v1#> ;
@prefix schema: <http://www.w3.org/2000/01/rdf-schema#> ;
property = madsrdf:authoritativeLabel :: xsd:string ;
        EOF
      end

      let(:subject_uri) { RDF::URI('http://id.loc.gov/authorities/names/n79021164') }

      let(:graph) do
        graph = RDF::Graph.new
        graph << [subject_uri, RDF::Vocab::MADS.authoritativeLabel, 'Mark Twain (passed in context)']
        graph
      end

      before do
        stub_request(:get, 'http://id.loc.gov/authorities/names/n79021164')
            .to_return(status: 200, body: webmock_fixture('loc_n79021164.nt'), headers: { 'Content-Type' => 'application/n-triples' })
      end

      context 'as false' do
        let(:expected_values) { ['Mark Twain (passed in context)', 'Twain, Mark, 1835-1910 (network call to LOC)'] }

        it 'returns values from context and network call' do
          result = subject.evaluate subject_uri, context: graph
          expect(result['property']).to match_array expected_values
        end
      end

      context 'as true' do
        let(:expected_values) { ['Mark Twain (passed in context)'] }

        it 'returns values from context only' do
          result = subject.evaluate(subject_uri, context: graph, limit_to_context: true)
          expect(result['property']).to match_array expected_values
        end
      end
    end
  end
end
