# frozen_string_literal: true
require 'spec_helper'
require 'rdf/turtle'
require 'rdf/spec/enumerable'
require 'rdf/spec/queryable'
require 'rdf/spec/countable'
require 'rdf/spec/mutable'

describe ActiveTriples::RDFSource do
  it_behaves_like 'an ActiveModel' do
    let(:am_lint_class) do
      class AMLintClass
        include ActiveTriples::RDFSource
      end
    end

    after { Object.send(:remove_const, :AMLintClass) if defined?(AMLintClass) }
  end

  before { @enumerable = subject }

  let(:source_class) { Class.new { include ActiveTriples::RDFSource } }
  let(:uri)          { RDF::URI('http://example.org/moomin') }

  subject { source_class.new }

  shared_context 'with properties' do
    let(:source_class) do
      class SourceWithCreator
        include ActiveTriples::RDFSource
        property :creator, predicate: RDF::Vocab::DC.creator
      end
      SourceWithCreator
    end

    let(:predicate) { RDF::Vocab::DC.creator }
    let(:property_name) { :creator }
  end

  describe 'RDF interface' do
    it { is_expected.to be_enumerable }
    it { is_expected.to be_queryable }
    it { is_expected.to be_countable }
    it { is_expected.to be_a_value }

    let(:enumerable) { source_class.new }
    it_behaves_like 'an RDF::Enumerable'

    let(:queryable) { enumerable }
    it_behaves_like 'an RDF::Queryable'

    let(:countable) { enumerable }
    it_behaves_like 'an RDF::Countable'

    let(:mutable) { enumerable }
    it_behaves_like 'an RDF::Mutable'

    describe 'Term behavior' do
      it { is_expected.to be_term }

      it 'is termified when added to an Statement' do
        expect(RDF::Statement(subject, nil, nil).subject).to eq subject
      end

      context 'as a node' do
        describe '#uri?' do
          it { is_expected.not_to be_uri }
        end

        describe '#node?' do
          it { is_expected.to be_node }
        end

        describe '#to_term' do
          its(:to_term) { is_expected.to be_node }
        end

        describe '#to_base' do
          its(:to_base) { is_expected.to be_a String }
          its(:to_base) { is_expected.to eq subject.to_term.to_base }
        end
      end

      context 'as a uri' do
        subject { source_class.new(uri) }

        describe '#uri?' do
          it { is_expected.to be_uri }
        end

        describe '#node?' do
          it { is_expected.not_to be_node }
        end

        describe '#to_term' do
          its(:to_term) { is_expected.to be_uri }
        end

        describe '#to_uri' do
          its(:to_uri) { is_expected.to be_uri }
        end

        describe '#to_base' do
          its(:to_base) { is_expected.to be_a String }
          its(:to_base) { is_expected.to eq subject.to_term.to_base }
        end
      end
    end
  end

  describe 'observers' do
    let(:observer) { double('observer') }

    before { subject.add_observer(observer) }

    include_context 'with properties'

    it 'notifies an observer of changes' do
      expect(observer)
        .to receive(:notify)
        .with(:creator, a_collection_containing_exactly('moomin'))

      subject.creator = 'moomin'
    end

    it 'notifies muliple observers of changes' do
      other_observer = double('second observer')
      values         = ['moomin', 'snork']

      expect(observer)
        .to receive(:notify)
        .with(:creator, a_collection_containing_exactly(*values))
      expect(other_observer)
        .to receive(:notify)
        .with(:creator, a_collection_containing_exactly(*values))

      subject.add_observer(other_observer)
      subject.creator = values
    end

    it 'does not notify removed observers' do
      expect(observer).not_to receive(:notify)

      subject.delete_observer(observer)

      subject.creator = 'moomin'
    end
  end

  describe '#==' do
    shared_examples 'Term equality' do
      it 'equals itself' do
        expect(subject).to eq subject
      end

      it 'equals its own Term' do
        expect(subject).to eq subject.to_term
      end

      it 'is symmetric' do
        expect(subject.to_term).to eq subject
      end

      it 'does not equal another term' do
        expect(subject).not_to eq RDF::Node.new
      end
    end

    include_examples 'Term equality'

    context 'with a URI' do
      include_examples 'Term equality' do
        subject { source_class.new(uri) }
      end
    end
  end

  describe '#attributes' do
    include_context 'with properties'

    it 'has bnode id' do
      expect(subject.attributes['id']).to eq subject.rdf_subject.id
    end

    it 'has empty properties' do
      expect(subject.attributes['creator']).to be_empty
    end

    it 'has registered properties' do
      subject.creator = 'moomin'
      expect(subject.attributes['creator']).to contain_exactly 'moomin'
    end

    it 'has unregistered properties' do
      predicate = RDF::OWL.sameAs
      subject << [subject, predicate, 'moomin']
      expect(subject.attributes[predicate.to_s]).to contain_exactly 'moomin'
    end

    context 'with uri' do
      subject { source_class.new(uri) }

      it 'has uri id' do
        expect(subject.attributes['id']).to eq subject.rdf_subject.to_s
      end

      it 'has creator' do
        subject.creator = 'moomin'
        expect(subject.attributes['creator']).to contain_exactly 'moomin'
      end
    end

    context 'with statements for other subjects' do
      before do
        subject <<
          RDF::Statement(RDF::URI('http://example.org/OTHER_SUBJECT'),
                         RDF::URI('http://example.org/ontology/OTHER_PRED'),
                         'OTHER_OBJECT')
      end

      it 'excludes values for statements not matching rdf_subject' do
        expect(subject.attributes.keys).not_to include 'http://example.org/ontology/OTHER_PRED'
        expect(subject.attributes.values).not_to include ['OTHER_OBJECT']
      end
    end
  end

  describe '#attributes=' do
    it 'raises an error when not passed a hash' do
      expect { subject.attributes = true }.to raise_error ArgumentError
    end
  end

  describe '#default_labels' do
    it 'prefers skos:prefLabel' do
      expect(subject.default_labels.first).to eq RDF::Vocab::SKOS.prefLabel
    end

    it 'values are all valid predicates' do
      subject.default_labels.each { |term| expect(term).to be_uri }
    end
  end

  describe '#fetch' do
    it 'raises an error when it is a node' do
      expect { subject.fetch }
        .to raise_error "#{subject} is a blank node; Cannot fetch a resource " \
                        'without a URI'
    end

    context 'with a valid URI' do
      subject { source_class.new(uri) }

      context 'with a bad link' do
        before { stub_request(:get, uri).to_return(status: 404) }

        it 'raises an error if no block is given' do
          expect { subject.fetch }.to raise_error IOError
        end

        it 'yields self to block' do
          expect { |block| subject.fetch(&block) }.to yield_with_args(subject)
        end
      end

      context 'with a working link' do
        before do
          stub_request(:get, uri).to_return(status: 200, body: graph.dump(:ttl))
        end

        let(:graph) { RDF::Graph.new << statement }

        let(:statement) do
          RDF::Statement(subject, RDF::Vocab::DC.title, 'moomin')
        end

        it 'loads retrieved graph into its own' do
          expect { subject.fetch }
            .to change { subject.statements.to_a }
            .from(a_collection_containing_exactly)
            .to(a_collection_containing_exactly(statement))
        end

        it 'merges retrieved graph into its own' do
          existing = RDF::Statement(subject, RDF::Vocab::DC.creator, 'Tove')
          subject << existing

          expect { subject.fetch }
            .to change { subject.statements.to_a }
            .from(a_collection_containing_exactly(existing))
            .to(a_collection_containing_exactly(statement, existing))
        end

        it 'passes extra arguments to RDF::Reader' do
          mime = 'x-humans/as-they-are'

          expect(RDF::Reader)
            .to receive(:open).with(subject.rdf_subject,
                                    base_uri: subject.rdf_subject,
                                    headers: { Accept: mime })
          subject.fetch(headers: { Accept: mime })
        end
      end
    end
  end

  describe '#graph_name' do
    it 'returns nil' do
      expect(subject.graph_name).to be_nil
    end
  end

  describe '#humanize' do
    it 'gives the "" for a node' do
      expect(subject.humanize).to eq ''
    end

    it 'gives a URI string for a URI resource' do
      allow(subject).to receive(:rdf_subject).and_return(uri)
      expect(subject.humanize).to eq uri.to_s
    end
  end

  describe '#inspect' do
    it 'includes bnode id' do
      expect(subject.inspect).to include subject.to_base
    end

    it 'includes uri' do
      subject.set_subject!('http://example.org/moomin')

      expect(subject.inspect).to include subject.to_base
    end
  end

  describe '#rdf_subject' do
    its(:rdf_subject) { is_expected.to be_a_node }

    context 'with a URI' do
      subject { source_class.new(uri) }

      its(:rdf_subject) { is_expected.to be_a_uri }
      its(:rdf_subject) { is_expected.to eq uri }
    end
  end

  describe '#rdf_label' do
    let(:label_prop) { RDF::Vocab::SKOS.prefLabel }

    it 'returns an array of label values' do
      expect(subject.rdf_label).to be_kind_of Array
    end

    it 'returns the default label values' do
      subject << [subject.rdf_subject, label_prop, 'Comet in Moominland']
      expect(subject.rdf_label).to contain_exactly('Comet in Moominland')
    end

    it 'prioritizes configured label values' do
      custom_label = RDF::URI('http://example.org/custom_label')
      subject.class.configure rdf_label: custom_label
      subject << [subject.rdf_subject, custom_label, RDF::Literal('New Label')]
      subject << [subject.rdf_subject, label_prop, 'Comet in Moominland']

      expect(subject.rdf_label).to contain_exactly('New Label')
    end
  end

  describe '#get_values' do
    include_context 'with properties'

    before { statements.each { |statement| subject << statement } }

    let(:values) { ['Tove Jansson', subject] }

    let(:statements) do
      values.map { |value| RDF::Statement(subject, predicate, value) }
    end

    context 'with no matching property' do
      it 'is empty' do
        expect(subject.get_values(:not_a_predicate))
          .to be_a_relation_containing
      end
    end

    context 'with an empty predicate' do
      it 'is empty' do
        expect(subject.get_values(RDF::URI('http://example.org/empty')))
          .to be_a_relation_containing
      end
    end

    it 'gets values for a property name' do
      expect(subject.get_values(property_name))
        .to be_a_relation_containing(*values)
    end

    it 'gets values for a predicate' do
      expect(subject.get_values(predicate))
        .to be_a_relation_containing(*values)
    end

    it 'gets values with two args' do
      val = 'momma'
      other_uri = uri / val
      subject << RDF::Statement(other_uri, predicate, val)

      expect(subject.get_values(other_uri, predicate))
        .to be_a_relation_containing(val)
    end
  end

  describe '#set_value' do
    it 'raises argument error when given too many arguments' do
      expect { subject.set_value(double, double, double, double) }
        .to raise_error ArgumentError
    end

    context 'when given an unregistered property name' do
      it 'raises an error' do
        expect { subject.set_value(:not_a_property, '') }.to raise_error do |e|
          expect(e).to be_a ActiveTriples::UndefinedPropertyError
          expect(e.klass).to eq subject.class
          expect(e.property).to eq :not_a_property
        end
      end

      it 'is a no-op' do
        subject << RDF::Statement(subject, RDF::Vocab::DC.title, 'Moomin')
        expect { subject.set_value(:not_a_property, '') rescue nil }
          .not_to change { subject.triples.to_a }
      end
    end

    shared_examples 'setting values' do
      include_context 'with properties'

      after do
        Object.send(:remove_const, 'SourceWithCreator') if
          defined? SourceWithCreator
      end

      let(:statements) do
        Array.wrap(value).map { |val| RDF::Statement(subject, predicate, val) }
      end

      it 'raises a ValueError when setting a nonsense value' do
        expect { subject.set_value(predicate, Object.new) }
          .to raise_error ActiveTriples::Relation::ValueError
      end

      it 'sets a value' do
        expect { subject.set_value(predicate, value) }
          .to change { subject.statements }
          .to(a_collection_containing_exactly(*statements))
      end

      it 'sets a value with a property name' do
        expect { subject.set_value(property_name, value) }
          .to change { subject.statements }
          .to(a_collection_containing_exactly(*statements))
      end

      it 'overwrites existing values' do
        old_vals = ['old value',
                    RDF::Node.new,
                    RDF::Vocab::DC.type,
                    RDF::URI('----')]

        subject.set_value(predicate, old_vals)

        expect { subject.set_value(predicate, value) }
          .to change { subject.statements }
          .to(a_collection_containing_exactly(*statements))
      end

      it 'returns the set values in a Relation' do
        expect(subject.set_value(predicate, value))
          .to be_a_relation_containing(*Array.wrap(value))
      end
    end

    context 'with string literal' do
      include_examples 'setting values' do
        let(:value) { 'moomin' }
      end
    end

    context 'with multiple values' do
      include_examples 'setting values' do
        let(:value) { %w('moominpapa moominmama') }
      end
    end

    context 'with typed literal' do
      include_examples 'setting values' do
        let(:value) { Date.today }
      end
    end

    context 'with RDF Term' do
      include_examples 'setting values' do
        let(:value) { RDF::Node.new }
      end
    end

    context 'with RDFSource node' do
      include_examples 'setting values' do
        let(:value) { source_class.new }
      end
    end

    context 'with RDFSource uri' do
      include_examples 'setting values' do
        let(:value) { source_class.new(uri) }
      end
    end

    context 'with self' do
      include_examples 'setting values' do
        let(:value) { subject }
      end
    end

    context 'with mixed values' do
      include_examples 'setting values' do
        let(:value) do
          ['moomin',
           Date.today,
           RDF::Node.new,
           source_class.new,
           source_class.new(uri),
           subject]
        end
      end
    end

    describe 'on child nodes' do
      let(:parent)  { source_class.new }
      let(:subject) { source_class.new(uri, parent) }

      include_examples 'setting values' do
        let(:value) do
          ['moomin',
           Date.today,
           RDF::Node.new,
           source_class.new,
           source_class.new(uri / 'new'),
           subject]
        end
      end

      it 'does not change parent' do
        property = RDF::Vocab::DC.title

        expect { subject.set_value(property, 'Comet in Moominland') }
          .not_to change { parent.to_a }
      end

      it 'persists to parent' do
        property = RDF::Vocab::DC.title

        subject.set_value(property, 'Comet in Moominland')

        expect { subject.persist! }
          .to change { parent.to_a }
          .to include RDF::Statement(subject, property, 'Comet in Moominland')
      end
    end

    context 'with reciprocal relations' do
      let(:document) { source_class.new }
      let(:person) { source_class.new }

      it 'handles setting reciprocally' do
        document.set_value(RDF::Vocab::DC.creator, person)
        person.set_value(RDF::Vocab::FOAF.publications, document)

        expect(person.get_values(RDF::Vocab::FOAF.publications))
          .to be_a_relation_containing(document)
        expect(document.get_values(RDF::Vocab::DC.creator))
          .to be_a_relation_containing(person)
      end

      it 'handles setting' do
        document.set_value(RDF::Vocab::DC.creator, person)
        person.set_value(RDF::Vocab::FOAF.knows, subject)
        subject.set_value(RDF::Vocab::FOAF.publications, document)
        subject.set_value(RDF::OWL.sameAs, subject)

        expect(subject.get_values(RDF::Vocab::FOAF.publications))
          .to be_a_relation_containing(document)
        expect(subject.get_values(RDF::OWL.sameAs))
          .to be_a_relation_containing(subject)
        expect(document.get_values(RDF::Vocab::DC.creator))
          .to be_a_relation_containing(person)
      end

      it 'handles setting circularly' do
        document.set_value(RDF::Vocab::DC.creator, [person, subject])
        person.set_value(RDF::Vocab::FOAF.knows, subject)

        expect(document.get_values(RDF::Vocab::DC.creator))
          .to be_a_relation_containing(person, subject)
        expect(person.get_values(RDF::Vocab::FOAF.knows))
          .to be_a_relation_containing subject
      end

      it 'handles setting circularly within ancestor list' do
        person2 = source_class.new
        subject.set_value(RDF::Vocab::DC.relation, document)
        document.set_value(RDF::Vocab::DC.relation, person)
        person.set_value(RDF::Vocab::DC.relation, person2)
        person2.set_value(RDF::Vocab::DC.relation, document)

        expect(person.get_values(RDF::Vocab::DC.relation))
          .to be_a_relation_containing person2
        expect(person2.get_values(RDF::Vocab::DC.relation))
          .to be_a_relation_containing document
      end
    end

    describe 'capturing child nodes' do
      let(:other)     { source_class.new }
      let(:predicate) { RDF::OWL.sameAs }

      it 'adds child node data to own graph' do
        other << RDF::Statement(:s, RDF::URI('p'), 'o')

        expect { subject.set_value(predicate, other) }
          .to change { subject.statements.to_a }
          .to include(*other.statements.to_a)
      end

      it 'does not change persistence strategy of added node' do
        expect { subject.set_value(predicate, other) }
          .not_to change { other.persistence_strategy }
      end

      it 'does not capture a child node when it already persists to a parent' do
        third = source_class.new
        third.set_value(predicate, other)

        child_other = third.get_values(predicate).first
        expect { subject.set_value(predicate, child_other) }
          .not_to change { child_other.persistence_strategy.parent }
      end

      context 'when setting to a relation' do
        it 'adds child node data to graph' do
          other << RDF::Statement(other, RDF::URI('p'), 'o')

          relation_source = source_class.new
          relation_source.set_value(predicate, other)
          relation = relation_source.get_values(predicate)

          expect { subject.set_value(predicate, relation) }
            .to change { subject.statements.to_a }
            .to include(*other.statements.to_a)
        end
      end
    end
  end

  describe 'validation' do
    let(:invalid_statement) do
      RDF::Statement.from([RDF::Literal.new('blah'),
                           RDF::Literal.new('blah'),
                           RDF::Literal.new('blah')])
    end

    it { is_expected.to be_valid }

    it 'is valid with valid statements' do
      subject.insert(*RDF::Spec.quads)
      expect(subject).to be_valid
    end

    it 'is valid with valid URI' do
      source_class.new(uri)
      expect(subject).to be_valid
    end

    context 'with invalid URI' do
      before do
        allow(subject).to receive(:rdf_subject).and_return(RDF::URI('----'))
      end

      it { is_expected.not_to be_valid }
    end

    context 'with invalid statement' do
      before { subject << invalid_statement }

      it 'is invalid' do
        expect(subject).to be_invalid
      end

      it 'adds error message' do
        expect { subject.valid? }
          .to change { subject.errors.messages }
          .from({})
          .to(base: ['The underlying graph must be valid'])
      end
    end

    context 'with ActiveModel validation' do
      let(:source_class) do
        class Validation
          include ActiveTriples::RDFSource

          validates_presence_of :title

          property :title, predicate: RDF::Vocab::DC.title
        end

        Validation
      end

      after { Object.send(:remove_const, :Validation) }

      context 'with invalid property' do
        it { is_expected.to be_invalid }

        it 'has errors' do
          expect { subject.valid? }
            .to change { subject.errors.messages }
            .from({})
            .to(title: ["can't be blank"])
        end
      end

      context 'when properties are valid' do
        before { subject.title = 'moomin' }

        it { is_expected.to be_valid }

        context 'and has invaild statements' do
          before { subject << invalid_statement }

          it { is_expected.to be_invalid }

          it 'has errors' do
            expect { subject.valid? }
              .to change { subject.errors.messages.transform_values { |v| v.map(&:to_s) } }
              .from({})
              .to(include(base: ['The underlying graph must be valid']))
          end
        end
      end
    end
  end

  describe '.apply_schema' do
    let(:dummy_source) { Class.new { include ActiveTriples::RDFSource } }

    before do
      class MyDataModel < ActiveTriples::Schema
        property :test_title, predicate: RDF::Vocab::DC.title
      end
    end

    after { Object.send(:remove_const, 'MyDataModel') }

    it 'should apply the schema' do
      dummy_source.apply_schema MyDataModel

      expect { dummy_source.new.test_title }.not_to raise_error
    end
  end
end
