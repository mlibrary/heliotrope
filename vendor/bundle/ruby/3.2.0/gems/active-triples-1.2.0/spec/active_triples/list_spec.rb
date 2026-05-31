# frozen_string_literal: true
require 'spec_helper'
require 'nokogiri'
require 'rdf/rdfxml'

describe ActiveTriples::List do
  subject { ActiveTriples::List.new }

  context 'when empty' do
    it 'has subject of RDF.nil' do
      expect(subject.subject).to eq RDF.nil
    end

    it 'has no statements' do
      expect(subject.statements.size).to eq 0
    end

    it 'knows it is empty' do
      expect(subject.size).to eq 0
      expect(subject).to be_empty
    end
  end

  context 'with elements' do
    before do
      subject << 1
      subject << 2
      subject << 3
    end

    it 'has a non-nil subject' do
      expect(subject.subject).not_to eq RDF.nil
    end

    it 'has type of rdf:List' do
      expect(subject.type.first).to eq RDF.List
    end

    it 'has correct number of elements' do
      expect(subject.length).to eq 3
    end

    context 'after clear' do
      before do
        subject.clear
        subject << 1
      end

      it 'has a type of rdf:List' do
        expect(subject.type.first).to eq RDF.List
      end

      it 'has correct number of elements' do
        expect(subject.length).to eq 1
      end
    end
  end

  context 'with properties' do
    before :each do
      class MADS < RDF::Vocabulary("http://www.loc.gov/mads/rdf/v1#")
        property :complexSubject
        property :authoritativeLabel
        property :elementList
        property :elementValue
        property :TopicElement
        property :TemporalElement
      end
      class DemoList
        include ActiveTriples::RDFSource
        property :elementList, :predicate => MADS.elementList, :class_name => 'DemoList::List'
        class List < ActiveTriples::List
          property :topicElement, :predicate => MADS.TopicElement, :class_name => 'DemoList::List::TopicElement'
          property :temporalElement, :predicate => MADS.TemporalElement, :class_name => 'DemoList::List::TemporalElement'

          class TopicElement
            include ActiveTriples::RDFSource
            configure :type => MADS.TopicElement
            property :elementValue, :predicate => MADS.elementValue
          end
          class TemporalElement
            include ActiveTriples::RDFSource
            configure :type => MADS.TemporalElement
            property :elementValue, :predicate => MADS.elementValue
          end
        end
      end
    end
    after(:each) do
      Object.send(:remove_const, :DemoList)
      Object.send(:remove_const, :MADS)
    end

    describe "a new list" do
      let (:ds) { DemoList.new('http://example.org/foo') }
      subject { ds.elementList.build}

      it "should insert at the end" do
        expect(subject).to be_kind_of DemoList::List
        expect(subject.size).to eq 0
        subject[1] = DemoList::List::TopicElement.new
        expect(subject.size).to eq 2
      end

      it "should insert at the head" do
        expect(subject).to be_kind_of DemoList::List
        expect(subject.size).to eq 0
        subject[0] = DemoList::List::TopicElement.new
        expect(subject.size).to eq 1
      end

      describe "that has 4 elements" do
        before do
          subject[3] = DemoList::List::TopicElement.new
          expect(subject.size).to eq 4
        end
        it "should insert in the middle" do
          subject[1] = DemoList::List::TopicElement.new
          expect(subject.size).to eq 4
        end
      end

      describe "return updated xml" do
        it "should be built" do
          subject[0] = RDF::URI.new "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
          subject[1] = DemoList::List::TopicElement.new
          subject[1].elementValue = "Relations with Mexican Americans"
          subject[2] = RDF::URI.new "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
          subject[3] = DemoList::List::TemporalElement.new
          subject[3].elementValue = "20th century"
          ds.elementList = subject
          doc = Nokogiri::XML(ds.dump(:rdfxml))
          ns = {rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#", mads: "http://www.loc.gov/mads/rdf/v1#"}
          expect(doc.xpath('/rdf:RDF/rdf:Description/@rdf:about', ns).map(&:value)).to eq ["http://example.org/foo"]
          expect(doc.xpath('//rdf:Description/mads:elementList/@rdf:parseType', ns).map(&:value)).to eq ["Collection"]
          expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 1]/@rdf:about', ns).map(&:value)).to eq ["http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"]
          expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 2]/mads:elementValue', ns).map(&:text)).to eq ["Relations with Mexican Americans"]
          expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 3]/@rdf:about', ns).map(&:value)).to eq ["http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"]
          expect(doc.xpath('//rdf:Description/mads:elementList/*[position() = 4]/mads:elementValue', ns).map(&:text)).to eq ["20th century"]
        end
      end
    end

    describe "an empty list" do
      subject { DemoList.new.elementList.build }
      it "should have to_ary" do
        expect(subject.to_ary).to eq []
      end
    end

    describe "a list that has a constructed element" do
      let(:ds) { DemoList.new('http://example.org/foo') }
      let(:list) { ds.elementList.build }
      let!(:topic) { list.topicElement.build }

      it "should have to_ary" do
        expect(list.to_ary.size).to eq 1
        expect(list.to_ary.first.class).to eq DemoList::List::TopicElement
      end

      describe 'clearing a list' do
        it "should be able to be cleared" do
          list.topicElement.build
          list.topicElement.build
          list.topicElement.build
          expect(list.size).to eq 4
          list.clear
          expect(list.size).to eq 0
        end

        it 'should allow elements to be added after clearing' do
          list.clear
          list.topicElement.build
          list.topicElement.build
          list.topicElement.build
          expect(list.size).to eq 3
        end
      end
    end

    describe "a list with content" do
      subject do
        subject = DemoList.new('http://example.org/foo')
        subject << RDF::RDFXML::Reader.for(:rdfxml).new(<<END
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:mads="http://www.loc.gov/mads/rdf/v1#">

        <mads:ComplexSubject rdf:about="http://example.org/foo">
          <mads:elementList rdf:parseType="Collection">
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"/>
            <mads:TopicElement>
              <mads:elementValue>Relations with Mexican Americans</mads:elementValue>
            </mads:TopicElement>
            <rdf:Description rdf:about="http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"/>
            <mads:TemporalElement>
              <mads:elementValue>20th century</mads:elementValue>
            </mads:TemporalElement>
          </mads:elementList>
        </mads:ComplexSubject>
      </rdf:RDF>
END
                                                        )

        subject
      end
      it "should have a subject" do
        expect(subject.rdf_subject.to_s).to eq "http://example.org/foo"
      end

      let (:list) { subject.elementList.first }

      it "should have fields" do
        expect(list.first.rdf_subject).to eq "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
        expect(list[1]).to be_kind_of DemoList::List::TopicElement
        expect(list[1].elementValue).to eq ["Relations with Mexican Americans"]
        expect(list[2].rdf_subject).to eq "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
        expect(list[3]).to be_kind_of DemoList::List::TemporalElement
        expect(list[3].elementValue).to eq ["20th century"]
      end

      it "should have each" do
        foo = []
        list.each { |n| foo << n.class }
        expect(foo).to eq [ActiveTriples::Resource,
                           DemoList::List::TopicElement,
                           ActiveTriples::Resource,
                           DemoList::List::TemporalElement]
      end

      it "should have to_ary" do
        ary = list.to_ary
        expect(ary.size).to eq 4

        expect(ary[1].elementValue)
          .to contain_exactly 'Relations with Mexican Americans'
      end

      it "should have size" do
        expect(list.size).to eq 4
      end


      describe "updating fields" do
        it "stores the values in a containing node" do
          list[3].elementValue = ["1900s"]
          doc = Nokogiri::XML(subject.dump :rdfxml)
          ns = {rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#", mads: "http://www.loc.gov/mads/rdf/v1#"}
          expect(doc.xpath('/rdf:RDF/mads:ComplexSubject/@rdf:about', ns).map(&:value))
            .to contain_exactly "http://example.org/foo"
          expect(doc.xpath('//mads:ComplexSubject/mads:elementList/@rdf:parseType', ns).map(&:value))
            .to contain_exactly "Collection"
          expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 1]/@rdf:about', ns).map(&:value))
            .to contain_exactly "http://library.ucsd.edu/ark:/20775/bbXXXXXXX6"
          expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 2]/mads:elementValue', ns).map(&:text))
            .to contain_exactly "Relations with Mexican Americans"
          expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 3]/@rdf:about', ns).map(&:value))
            .to contain_exactly "http://library.ucsd.edu/ark:/20775/bbXXXXXXX4"
          expect(doc.xpath('//mads:ComplexSubject/mads:elementList/*[position() = 4]/mads:elementValue', ns).map(&:text))
            .to contain_exactly "1900s"
          expect(RDF::List.new(subject: list.rdf_subject, graph: subject)).to be_valid
        end

        it "should be a valid list" do
          list << "Val"
          expect(RDF::List.new(subject: list.rdf_subject, graph: subject)).to be_valid
        end
      end
    end
  end
end
