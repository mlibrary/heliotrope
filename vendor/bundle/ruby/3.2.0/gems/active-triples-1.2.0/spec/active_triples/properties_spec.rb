# frozen_string_literal: true
require "spec_helper"
describe ActiveTriples::Properties do
  before do
    class DummyProperties
      include ActiveTriples::Reflection
      include ActiveTriples::Properties
    end
  end

  after do
    Object.send(:remove_const, "DummyProperties")
  end

  describe '#property' do
    it 'sets a property as a NodeConfig' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title
      expect(DummyProperties.reflect_on_property(:title)).to be_kind_of ActiveTriples::NodeConfig
    end

    it 'sets the correct property' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title
      expect(DummyProperties.reflect_on_property(:title).predicate).to eql RDF::Vocab::DC.title
    end

    it 'sets the correct property from string' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title.to_s
      expect(DummyProperties.reflect_on_property(:title).predicate).to eql RDF::Vocab::DC.title
    end

    it 'sets index behaviors' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title do |index|
        index.as :facetable, :searchable
      end
      expect(DummyProperties.reflect_on_property(:title)[:behaviors])
        .to eq [:facetable, :searchable]
    end

    it 'sets class name' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title, :class_name => RDF::Literal
      expect(DummyProperties.reflect_on_property(:title)[:class_name]).to eq RDF::Literal
    end

    it 'sets persistence strategy' do
      DummyProperties
        .property :title, :predicate => RDF::Vocab::DC.title, :persist_to => :moomin
      expect(DummyProperties.reflect_on_property(:title)[:persist_to]).to eq :moomin
    end

    it 'sets arbitrary properties' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title, :moomin => :moomin
      expect(DummyProperties.reflect_on_property(:title)[:moomin]).to eq :moomin
    end

    it 'constantizes string class names' do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title, :class_name => "RDF::Literal"
      expect(DummyProperties.reflect_on_property(:title)[:class_name]).to eq RDF::Literal
    end

    it "keeps strings which it can't constantize as strings" do
      DummyProperties.property :title, 
                               :predicate => RDF::Vocab::DC.title, 
                               :class_name => "FakeClassName"
      expect(DummyProperties.reflect_on_property(:title)[:class_name]).to eq "FakeClassName"
    end

    it 'raises error when defining properties that are already methods' do
      DummyProperties.send :define_method, :type, lambda { }
      expect { DummyProperties.property :type, predicate: RDF::Vocab::DC.type }
        .to raise_error ArgumentError
    end

    it 'raises error when defining properties with no predicate' do
      expect { DummyProperties.property :type }.to raise_error ArgumentError
    end

    it 'raises error when defining properties with a non-Roesource predicate' do
      expect { DummyProperties.property :type, :predicate => 123 }.to raise_error ArgumentError
    end

    it 'raises error when defining properties already have method setters' do
      DummyProperties.send :define_method, :type=, lambda { }
      expect { DummyProperties.property :type, :predicate => RDF::Vocab::DC.type }.to raise_error ArgumentError
    end

    it 'allows resetting of properties' do
      DummyProperties.property :title, predicate: RDF::Vocab::DC.alternative
      DummyProperties.property :title, predicate: RDF::Vocab::DC.title
      expect(DummyProperties.reflect_on_property(:title).predicate)
        .to eq RDF::Vocab::DC.title
    end
  end

  describe '#config_for_term_or_uri' do
    before do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title
    end

    it 'finds property configuration by term symbol' do
      expect(DummyProperties.config_for_term_or_uri(:title))
        .to eq DummyProperties.properties['title']
    end

    it 'finds property configuration by term string' do
      expect(DummyProperties.config_for_term_or_uri('title'))
        .to eq DummyProperties.properties['title']
    end

    it 'finds property configuration by term URI' do
      expect(DummyProperties.config_for_term_or_uri(RDF::Vocab::DC.title))
        .to eq DummyProperties.properties['title']
    end
  end

  describe '#fields' do
    before do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title
      DummyProperties.property :name, :predicate => RDF::Vocab::FOAF.name
    end

    it 'lists its terms' do
      expect(DummyProperties.fields).to contain_exactly(:title, :name)
    end
  end

  context "when using a subclass" do
    before do
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title
      class DummySubClass < DummyProperties
        property :source, :predicate => RDF::Vocab::DC11[:source]
      end
    end

    after do
      Object.send(:remove_const, "DummySubClass")
    end

    it 'should carry properties from superclass' do
      expect(DummySubClass.reflect_on_property(:title))
        .to be_kind_of ActiveTriples::NodeConfig
      expect(DummySubClass.reflect_on_property(:source))
        .to be_kind_of ActiveTriples::NodeConfig
    end
  end

  describe '#generated_property_methods' do
    it 'returns a GeneratedPropertyMethods module' do 
      expect(DummyProperties.generated_property_methods)
        .to eq DummyProperties::GeneratedPropertyMethods
    end

    it 'has setter and getter instance methods for set properties' do 
      DummyProperties.property :title, :predicate => RDF::Vocab::DC.title
      expect(DummyProperties.generated_property_methods.instance_methods)
        .to contain_exactly(:title, :title=)
    end
  end
end
