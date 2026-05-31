# frozen_string_literal: true
require 'spec_helper'
require 'active_model'

describe ActiveTriples::Identifiable do
  before do
    class ActiveExample; include ActiveTriples::Identifiable; end
  end

  after do
    Object.send(:remove_const, 'ActiveExample')
  end

  subject { ActiveExample.new }
  let(:klass) { ActiveExample }

  shared_context 'with data' do
    let(:parent) { MyResource.new }

    before do
      class MyResource
        include ActiveTriples::RDFSource
        property :relation, predicate: RDF::Vocab::DC.relation, class_name: 'ActiveExample'
      end

      klass.property :title, predicate: RDF::Vocab::DC.title
      klass.property :identifier, predicate: RDF::Vocab::DC.identifier
      klass.property :description, predicate: RDF::Vocab::DC.description

      subject.resource.title = 'Moomin Valley in November'
      subject.resource.identifier = 'moomvember'
      subject.resource.description = 'The ninth and final book in the Moomin series by Finnish author Tove Jansson'
      parent.relation = subject
    end

    after do
      Object.send(:remove_const, 'MyResource')
    end
  end

  context 'without implementation' do
    describe '::from_uri' do
      it 'raises a NotImplementedError' do
       expect{ klass.from_uri(RDF::URI('http://example.org/blah')) }.to raise_error NotImplementedError
      end
    end

    describe '#to_uri' do
      it 'raises a NotImplementedError' do
       expect{ subject.to_uri }.to raise_error NotImplementedError
      end
    end
  end

  context 'with implementation' do
    before do
      class ActiveExample
        attr_accessor :id
        configure base_uri: 'http://example.org/ns/'

        def self.property(*args)
          prop = args.first

          define_method prop.to_s do
            resource.get_values(prop)
          end

          define_method "#{prop.to_s}=" do |*args|
            resource.set_value(prop, *args)
          end

          resource_class.property(*args)
        end

      end

      subject.id = '123'
    end

    describe '::properties' do
      before do
        klass.property :title, :predicate => RDF::Vocab::DC.title
      end
      it 'can be set' do
        expect(klass.properties).to include 'title'
      end

      it 'sets property values' do
        subject.title = 'Finn Family Moomintroll'
        expect(subject.resource.title).to eq ['Finn Family Moomintroll']
      end

      it 'appends property values' do
        subject.title << 'Finn Family Moomintroll'
        expect(subject.resource.title).to eq ['Finn Family Moomintroll']
      end

      it 'returns correct values in property getters' do
        subject.resource.title = 'Finn Family Moomintroll'
        expect(subject.title).to eq subject.resource.title
      end

      context 'with other identifiable classes' do
        before do
          class ActiveExampleTwo
            include ActiveTriples::Identifiable
          end
        end
        after do
          Object.send(:remove_const, 'ActiveExampleTwo')
        end

        it 'does not effect other classes' do
          klass.property :identifier, :predicate => RDF::Vocab::DC.identifier
          expect(ActiveExampleTwo.properties).to be_empty
        end
      end
    end

    describe '::configure' do
      it 'allows configuration' do
        klass.configure type: RDF::OWL.Thing
        expect(subject.resource.type).to eq [RDF::OWL.Thing]
      end
    end

    describe '#parent' do
      it 'is nil' do
        expect(subject.parent).to be_nil
      end

      context 'with relationships' do
        include_context 'with data'

        it 'has a parent' do
          expect(parent.relation.first.parent).to eq parent
        end
      end
    end

    describe '#parent=' do
      before { class MyResource; include ActiveTriples::RDFSource; end }
      let(:parent) { MyResource.new }

      it 'sets parent' do
        expect { subject.parent = parent }
          .to change { subject.parent }.from(nil).to(parent)
      end
    end

    describe '#rdf_subject' do
      it 'has a subject' do
        expect(subject.rdf_subject).to eq 'http://example.org/ns/123'
      end
    end

    describe '#to_uri' do
      it 'has a subject' do
        expect(subject.rdf_subject).to eq 'http://example.org/ns/123'
      end
    end

    describe "adding it as a property for an AT Resource" do
      include_context 'with data'
      it "returns the same in-memory object added" do
        resource = MyResource.new
        resource.relation = subject

        expect(resource.relation).to eq [subject]
      end
      it "can share that object with another resource" do
        resource = MyResource.new
        resource_2 = MyResource.new

        resource.relation = subject
        resource_2.relation = resource.relation

        expect(resource.relation).to eq resource_2.relation
      end
    end
  end
end
