# frozen_string_literal: true
require 'spec_helper'

describe "nesting attribute behavior" do
  describe ".attributes=" do
    describe "complex properties" do
      before do
        class DummyMADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
          # componentList and Types of components
          property :componentList
          property :Topic
          property :Temporal
          property :PersonalName
          property :CorporateName
          property :ComplexSubject


          # elementList and elementList values
          property :elementList
          property :elementValue
          property :TopicElement
          property :TemporalElement
          property :NameElement
          property :FullNameElement
          property :DateNameElement
        end

        class ComplexResource
          include ActiveTriples::RDFSource
          property :topic, predicate: DummyMADS.Topic, class_name: "Topic"
          property :personalName, predicate: DummyMADS.PersonalName, class_name: "PersonalName"
          property :title, predicate: RDF::Vocab::DC.title


          accepts_nested_attributes_for :topic, :personalName

          class Topic
            include ActiveTriples::RDFSource
            property :elementList, predicate: DummyMADS.elementList, class_name: "ComplexResource::ElementList"
            accepts_nested_attributes_for :elementList
          end
          class PersonalName
            include ActiveTriples::RDFSource
            property :elementList, predicate: DummyMADS.elementList, class_name: "ComplexResource::ElementList"
            property :extraProperty, predicate: DummyMADS.elementValue, class_name: "ComplexResource::Topic"
            accepts_nested_attributes_for :elementList, :extraProperty
          end
          class ElementList < ActiveTriples::List
            configure type: DummyMADS.elementList
            property :topicElement, predicate: DummyMADS.TopicElement, class_name: "ComplexResource::MadsTopicElement"
            property :temporalElement, predicate: DummyMADS.TemporalElement
            property :fullNameElement, predicate: DummyMADS.FullNameElement
            property :dateNameElement, predicate: DummyMADS.DateNameElement
            property :nameElement, predicate: DummyMADS.NameElement
            property :elementValue, predicate: DummyMADS.elementValue
            accepts_nested_attributes_for :topicElement
          end
          class MadsTopicElement
            include ActiveTriples::RDFSource
            configure :type => DummyMADS.TopicElement
            property :elementValue, predicate: DummyMADS.elementValue
          end
        end
      end
      after do
        Object.send(:remove_const, :ComplexResource)
        Object.send(:remove_const, :DummyMADS)
      end
      subject { ComplexResource.new }
      let(:params) do
        { myResource:
          {
            topic_attributes: {
              '0' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: [{
                    id: 'http://library.ucsd.edu/ark:/20775/bb3333333x',
                    elementValue:"Cosmology"
                     }]
                  }]
              },
              '1' =>
              {
                elementList_attributes: [{
                  topicElement_attributes: {'0' => {elementValue:"Quantum Behavior"}}
                }]
              }
            },
            personalName_attributes: [
              {
                id: 'http://library.ucsd.edu/ark:20775/jefferson',
                elementList_attributes: [{
                  fullNameElement: "Jefferson, Thomas",
                  dateNameElement: "1743-1826"
                }]
              }
              #, "Hemings, Sally"
            ],
          }
        }
      end

      describe "on lists" do
        subject { ComplexResource::PersonalName.new }
        it "should accept a hash" do
          subject.elementList_attributes =  [{ topicElement_attributes: {'0' => { elementValue:"Quantum Behavior" }, '1' => { elementValue:"Wave Function" }}}]
          expect(subject.elementList.first[0].elementValue)
            .to contain_exactly "Quantum Behavior"
          expect(subject.elementList.first[1].elementValue)
            .to contain_exactly "Wave Function"
        end

        it "should accept an array" do
          subject.elementList_attributes =  [{ topicElement_attributes: [{ elementValue:"Quantum Behavior" }, { elementValue:"Wave Function" }]}]
          expect(subject.elementList.first[0].elementValue)
            .to contain_exactly "Quantum Behavior"
          expect(subject.elementList.first[1].elementValue)
            .to contain_exactly "Wave Function"
        end
      end

      context "from nested objects" do
        before do
          # Replace the graph's contents with the Hash
          subject.attributes = params[:myResource]
        end

        it 'should have attributes' do
          expect(subject.topic.map { |topic| topic.elementList.first[0].elementValue })
            .to contain_exactly ['Cosmology'], ['Quantum Behavior']
          expect(subject.personalName.first.elementList.first.fullNameElement)
            .to contain_exactly "Jefferson, Thomas"
          expect(subject.personalName.first.elementList.first.dateNameElement)
            .to contain_exactly "1743-1826"
        end

        it 'should build nodes with ids' do
          expect(subject.topic.map { |v| v.elementList.first[0].rdf_subject })
            .to include 'http://library.ucsd.edu/ark:/20775/bb3333333x'
          expect(subject.personalName.map(&:rdf_subject))
            .to include 'http://library.ucsd.edu/ark:20775/jefferson'
        end

        it 'should fail when writing to a non-predicate' do
          attributes = { topic_attributes: { '0' => { elementList_attributes: [{ topicElement_attributes: [{ fake_predicate:"Cosmology" }] }]}}}
          expect{ subject.attributes = attributes }.to raise_error ArgumentError
        end

        it 'should fail when writing to a non-predicate with a setter method' do
          attributes = { topic_attributes: { '0' => { elementList_attributes: [{ topicElement_attributes: [{ name:"Cosmology" }] }]}}}
          expect{ subject.attributes = attributes }.to raise_error ArgumentError
        end
      end
    end

    context "a simple model" do
      before do
        class SpecResource
          include ActiveTriples::RDFSource
          property :parts, predicate: RDF::Vocab::DC.hasPart, :class_name=>'Component'
          accepts_nested_attributes_for :parts, allow_destroy: true

          class Component
            include ActiveTriples::RDFSource
            property :label, predicate: RDF::Vocab::DC.title
          end
        end

        SpecResource.accepts_nested_attributes_for *args
      end
      after { Object.send(:remove_const, :SpecResource) }

      let(:args) { [:parts] }
      subject { SpecResource.new }

      context "for an existing B-nodes" do
        before do
          subject.attributes = { parts_attributes: [
                                   {label: 'Alternator'},
                                   {label: 'Distributor'},
                                   {label: 'Transmission'},
                                   {label: 'Fuel Filter'}]}
          subject.parts_attributes = new_attributes
        end

        context "that allows destroy" do
          let(:args)               { [:parts, allow_destroy: true] }
          let (:replace_object_id) { subject.parts[1].rdf_subject.to_s }
          let (:remove_object_id)  { subject.parts[3].rdf_subject.to_s }

          let(:new_attributes) do
            [{ id: replace_object_id, label: "Universal Joint" },
             { label:"Oil Pump" },
             { id: remove_object_id, _destroy: '1', label: "bar1 uno" }]
          end

          it "should update nested objects" do
            expect(subject.parts.map { |p| p.label.first })
              .to contain_exactly 'Universal Joint', 'Oil Pump', 
                                  an_instance_of(String), an_instance_of(String)
          end
        end

        context "when an id is provided" do
          let(:new_attributes) { [{ id: 'http://example.com/part#1', label: "Universal Joint" }] }

          it "creates a new statement" do
            expect(subject.parts.map(&:rdf_subject))
              .to include RDF::URI('http://example.com/part#1')
          end
        end
      end

      context "for an existing resources" do
        before do
          subject.attributes = { parts_attributes: [
                                    { id: 'http://id.loc.gov/authorities/subjects/sh85010251' },
                                    { id: 'http://id.loc.gov/authorities/subjects/sh2001009145' }]}
          subject.parts_attributes = new_attributes
        end

        let(:args) { [:parts] }

        let(:new_attributes) { [{ id: 'http://id.loc.gov/authorities/subjects/sh85010251' },
                                { id: 'http://id.loc.gov/authorities/subjects/sh2001009145' },
                                { id: 'http://id.loc.gov/authorities/subjects/sh85052223' }] }

        it "should update nested objects" do
          expect(subject.parts.map{|p| p.id})
            .to contain_exactly "http://id.loc.gov/authorities/subjects/sh85010251", 
                                "http://id.loc.gov/authorities/subjects/sh2001009145", 
                                "http://id.loc.gov/authorities/subjects/sh85052223"
        end
      end


      context "for a new B-node" do
        context "when called with reject_if" do
          let(:args) { [:parts, reject_if: reject_proc] }
          let(:reject_proc) { lambda { |attributes| attributes[:label] == 'Bar' } }
          let(:new_attributes) { [{ label: "Universal Joint" }, { label: 'Bar'} ] }
          before { subject.parts_attributes = new_attributes }

          it "should call the reject if proc" do
            expect(subject.parts.map(&:label))
              .to contain_exactly(['Universal Joint'])
          end
        end
      end
    end
  end
end
