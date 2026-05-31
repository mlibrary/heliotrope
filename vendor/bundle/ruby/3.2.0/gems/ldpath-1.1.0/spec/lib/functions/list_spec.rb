require 'spec_helper'

describe "LDPath list functions" do
  let(:object) { RDF::URI.new("info:a") }

  let(:graph) do
    graph = RDF::Graph.new
    l = RDF::List[1, 2, 3]
    graph << [object, RDF::URI.new("http://example.com/list"), l]
    graph << l
    graph
  end

  subject do
    program.evaluate object, context: graph
  end

  describe "fn:flatten" do
    let(:program) do
      Ldpath::Program.parse <<-EOF
        @prefix ex : <http://example.com/> ;
        list_items = fn:flatten(ex:list) :: xsd:string ;
      EOF
    end

    it "collapses the RDF list into individual values" do
      expect(subject["list_items"]).to match_array ["1", "2", "3"]
    end
  end

  describe "fn:flatten" do
    let(:program) do
      Ldpath::Program.parse <<-EOF
        @prefix ex : <http://example.com/> ;
        list_item = fn:get(ex:list, 1) :: xsd:string ;
      EOF
    end

    it "extracts a single term by position from the RDF list" do
      expect(subject["list_item"]).to eq ["2"]
    end
  end

  describe "fn:subList" do
    let(:program) do
      Ldpath::Program.parse <<-EOF
        @prefix ex : <http://example.com/> ;
        list_items = fn:subList(ex:list, 1) :: xsd:string ;
        list_items_by_range = fn:subList(ex:list, 0, 1) :: xsd:string ;
      EOF
    end

    it "extracts a list of terms by index" do
      expect(subject["list_items"]).to eq ["2", "3"]
    end

    it "selects the range, inclusively" do
      expect(subject["list_items_by_range"]).to eq ["1", "2"]
    end
  end
end
