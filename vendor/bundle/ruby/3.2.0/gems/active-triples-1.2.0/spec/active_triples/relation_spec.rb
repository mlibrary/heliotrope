# frozen_string_literal: true
require 'spec_helper'
require 'rdf/isomorphic'

describe ActiveTriples::Relation do
  let(:parent_resource) { double('parent resource', reflections: {}) }
  let(:value_args)      { double('value args', last: {}) }

  let(:uri) { RDF::URI('http://example.org/moomin') }

  subject { described_class.new(parent_resource, value_args) }

  shared_context 'with URI property' do
    subject { described_class.new(parent_resource, [property]) }

    let(:property) { uri }
  end

  shared_context 'with symbol property' do
    subject { described_class.new(parent_resource, [property]) }

    let(:property) { :moomin }

    let(:reflections) do
      Class.new do
        include ActiveTriples::RDFSource

        property :moomin, predicate: RDF::URI('http://example.org/moomin')
      end
    end

    before do
      allow(parent_resource).to receive(:reflections).and_return(reflections)
    end
  end

  shared_context 'with unregistered property' do
    subject { described_class.new(parent_resource, [property]) }

    let(:property)    { :moomin }
    let(:reflections) { Class.new { include ActiveTriples::RDFSource } }

    before do
      allow(parent_resource).to receive(:reflections).and_return(reflections)
    end
  end

  shared_context 'with other relation' do
    let(:other_class) do
      Class.new do
        include ActiveTriples::RDFSource
        property :snork, predicate: RDF::URI('http://example.org/snork')
      end
    end

    let(:other)          { described_class.new(other_parent, other_args) }
    let(:other_args)     { [other_property] }
    let(:other_parent)   { other_class.new }
    let(:other_property) { :snork }
  end

  [:&, :|, :+].each do |array_method|
    describe "#{array_method}" do
      shared_examples 'array method behavior' do
        it "behaves like `Array##{array_method}`" do
          expect(subject.send(array_method.to_sym, other_array))
            .to contain_exactly(*subject.to_a.send(array_method.to_sym,
                                                   other_array.to_a))
        end
      end

      context 'with #to_ary as argument' do
        include_context 'with symbol property'

        let(:parent_resource) { ActiveTriples::Resource.new }

        context 'when empty' do
          context 'with empty other' do
            it_behaves_like 'array method behavior' do
              let(:other_array) { [] }
            end
          end

          context 'with values in other' do
            it_behaves_like 'array method behavior' do
              let(:other_array) { [1, 'two', RDF::URI('uri'), RDF::Node.new] }
            end
          end
        end

        context 'with values' do
          before { subject << [RDF::Node.new, 'two', 3] }

          context 'with empty other' do
            it_behaves_like 'array method behavior' do
              let(:other_array) { [] }
            end
          end

          context 'with values in other' do
            it_behaves_like 'array method behavior' do
              let(:other_array) { [1, 'two', RDF::URI('uri'), RDF::Node.new] }
            end
          end
        end
      end
    end
  end

  describe '#&' do
    context 'with relation as argument' do
      include_context 'with symbol property'
      let(:parent_resource) { ActiveTriples::Resource.new }

      include_context 'with other relation'

      it { expect(subject & other).to be_empty }

      it 'handles node equality' do
        node = RDF::Node.new

        subject << [1, node]
        other   << [2, node]

        expect(subject & other).to contain_exactly(have_rdf_subject(node))
      end

      it 'handles literal equality' do
        literal      = RDF::Literal('mummi')
        lang_literal = RDF::Literal('mummi', language: :fi)

        subject << [1, literal]
        other   << [2, lang_literal]

        expect(subject & other).to be_empty

        subject << [1, lang_literal]
        expect(subject & other).to contain_exactly lang_literal
      end
    end
  end

  describe '#|' do
    context 'with relation as argument' do
      include_context 'with symbol property'
      let(:parent_resource) { ActiveTriples::Resource.new }

      include_context 'with other relation'

      it 'handles node equality' do
        node = RDF::Node.new

        subject << [1, node]
        other   << [2, node]

        expect(subject | other).to contain_exactly(1, 2, have_rdf_subject(node))
      end

      it 'handles literal equality' do
        literal      = RDF::Literal('mummi')
        lang_literal = RDF::Literal('mummi', language: :fi)

        subject << [1, literal]
        other   << [2, lang_literal]

        expect(subject | other).to contain_exactly('mummi', lang_literal, 1, 2)
      end
    end
  end

  describe '#+' do
    context 'with relation as argument' do
      include_context 'with symbol property'
      let(:parent_resource) { ActiveTriples::Resource.new }

      include_context 'with other relation'

      it 'still implements as ' do
        subject << [RDF::Node.new, RDF::Node.new,
                    RDF::Literal('mummi'), RDF::Literal('mummi', language: :fi)]
        other   << [RDF::Node.new, RDF::Node.new,
                    RDF::Literal('mummi'), RDF::Literal('mummi', language: :fi)]

        expect(subject + other).to contain_exactly(*(subject.to_a + other.to_a))
      end
    end
  end

  describe '#<=>' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }

    shared_examples 'a comparable relation' do
      it 'gives 0 when both are empty' do
        expect(subject <=> other).to eq 0
      end

      it 'gives nil when not comparable' do
        subject << 1
        expect(subject <=> other).to be_nil
      end

      types = { numeric: [0, 1, 2, 3_000_000_000],
                string:  ['moomin', 'snork', 'snufkin'],
                lang:    [RDF::Literal('Moomin', language: :en),
                          RDF::Literal('Mummi', language: :fi)],
                date:    [Date.today, Date.today - 1],
                uri:     [RDF::URI('one'), RDF::URI('two'), RDF::URI('three')],
                node:    [RDF::Node.new, RDF::Node.new],
              }

      types.each do |type, values|
        it "gives 0 when containing the same #{type} elements" do
          subject << 1
          other   << 1
          expect(subject <=> other).to eq 0
        end
      end

      context 'with varied elements' do
        before do
          types.each do |_, values|
            values.each do |value|
              subject << value
              other   << value
            end
          end
        end

        it "gives 0 when containing the same varied elements" do
          expect(subject <=> other).to eq 0
        end

        it "gives nil when other contains a subset of varied elements" do
          subject << 'extra'
          expect(subject <=> other).to be_nil
        end

        it "gives nil when other contains a superset of varied elements" do
          other << 'extra'
          expect(subject <=> other).to be_nil
        end

        it "gives nil when other contains a subset by language" do
          subject << RDF::Literal("Moomin", language: :aa)
          expect(subject <=> other).to be_nil
        end

        it "gives nil when other contains a superset by language" do
          other << RDF::Literal("Moomin", language: :aa)
          expect(subject <=> other).to be_nil
        end
      end
    end

    context 'when other is a Relation' do
      include_context 'with other relation'
      it_behaves_like 'a comparable relation'

      context 'and without cast' do
        let(:other_args)   { [other_property, cast: false] }
        it_behaves_like 'a comparable relation'
      end

      context 'and with return_literals' do
        let(:other_args)   { [other_property, return_literals: true] }
        it_behaves_like 'a comparable relation'
      end
    end

    context 'when other is an Array' do
      let(:other) { [] }

      it_behaves_like 'a comparable relation'
    end
  end

  describe '#build' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }

    it 'returns a new child node' do
      expect(subject.build).to be_a ActiveTriples::RDFSource
    end

    it 'adds new child node to relation' do
      expect { subject.build }.to change { subject.count }.by 1
    end

    it 'builds child as new blank node by default' do
      expect(subject.build).to be_node
    end

    it 'builds child with uri if given' do
      uri = 'http://example.com/moomin'
      expect(subject.build(id: uri)).to be_uri
    end

    context 'when cast is false' do
      include_context 'with symbol property' do
        before do
          reflections.property :moomin,
                               cast:       false,
                               predicate:  RDF::Vocab::DC.relation
        end
      end

      it 'still returns as a resource' do
        expect(subject.build).to be_a ActiveTriples::RDFSource
      end

      it 'adds a new child node to the relation' do
        expect { subject.build }.to change { subject.count }.by 1
      end
    end

    context 'with configured properties' do
      include_context 'with symbol property' do
        before do
          reflections.property :moomin,
                               predicate:  RDF::Vocab::DC.relation,
                               class_name: 'WithTitle'
          class WithTitle
            include ActiveTriples::RDFSource

            property :title, predicate: RDF::Vocab::DC.title
          end
        end

        after { Object.send(:remove_const, :WithTitle) }
      end

      it 'sets attributes for built node' do
        attributes = { title: 'moomin' }

        expect(subject.build(attributes))
          .to have_attributes(title: ['moomin'])
      end
    end
  end

  describe '#delete' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }

    it 'handles a non-existent value' do
      expect { subject.delete(1) }.not_to change { subject.to_a }
    end

    it 'does not notify observers when no changes are made' do
      observer = double(:observer)
      parent_resource.add_observer(observer)

      expect(observer).not_to receive(:notify)

      subject.delete(1)
    end

    context 'with values' do
      before { subject << values }

      let(:node) { RDF::Node.new(:node) }
      let(:uri) { RDF.Property }
      let(:values) { ['1', 1, :one, false, DateTime.now, node, uri] }

      it 'handles a non-existent value' do
        expect { subject.delete('blah') }.not_to change { subject.to_a }
      end

      it 'deletes a matched value' do
        expect { subject.delete(values.first) }
          .to change { subject.to_a }
          .to contain_exactly(*values[1..-1])
      end

      it 'notifies observers of changes' do
        observer = double(:observer)
        parent_resource.add_observer(observer)

        expect(observer).to receive(:notify)
          .with(subject.property,
                a_collection_containing_exactly(*values[1..-1]))

        subject.delete(values.first)
      end

      it 'deletes a URI value' do
        values.delete(uri)
        expect { subject.delete(uri) }
          .to change { subject.to_a }
          .to contain_exactly(*values)
      end

      it 'deletes a node value' do
        values.delete(node)
        expect { subject.delete(node) }
          .to change { subject.to_a }
          .to contain_exactly(*values)
      end

      it 'deletes a token value' do
        values.delete(:one)
        expect { subject.delete(:one) }
          .to change { subject.to_a }
          .to contain_exactly(*values)
      end
    end
  end

  describe '#delete?' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }
    let(:observer)        { double(:observer) }

    it 'gives nil for non-existant value' do
      expect(subject.delete?(1)).to be_nil
    end

    it 'does not notify observers when no changes are made' do
      parent_resource.add_observer(observer)

      expect(observer).not_to receive(:notify)
      subject.delete?(1)
    end

    it 'returns value when deleted' do
      subject.set(1)
      expect(subject.delete?(1)).to eq 1
    end

    it 'deletes existing values' do
      subject.set(1)
      expect { subject.delete?(1) }
        .to change { subject.to_a }.to be_empty
    end

    it 'notifies observers of changes' do
      subject.set(1)
      parent_resource.add_observer(observer)

      expect(observer).to receive(:notify)
        .with(subject.property, be_empty)

      subject.delete?(1)
    end
  end

  describe '#subtract' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }
    let(:observer)        { double(:observer) }

    it 'subtracts values as arguments' do
      subject.set([1, 2, 3])
      expect { subject.subtract(2, 3) }
        .to change { subject.to_a }.to contain_exactly(1)
    end

    it 'subtracts values as an enumerable' do
      subject.set([1, 2, 3])
      expect { subject.subtract([2, 3]) }
        .to change { subject.to_a }.to contain_exactly(1)
    end

    it 'subtracts token values' do
      subject.set([:one, :two, :three])
      expect { subject.subtract([:two, :three]) }
        .to change { subject.to_a }.to contain_exactly(:one)
    end

    it 'notifies observers of changes' do
      subject.set([1, 2, 3])
      parent_resource.add_observer(observer)

      expect(observer).to receive(:notify)
        .with(subject.property, a_collection_containing_exactly(1))

      subject.subtract([2, 3])
    end
  end

  describe '#swap' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }

    it 'returns nil when the value is not present' do
      expect(subject.swap(1, 2)).to be_nil
    end

    it 'does not change contents for non-existent value' do
      expect { subject.swap(1, 2) }.not_to change { subject.to_a }
    end

    it 'swaps the value' do
      values = [1, 2, 3]
      subject.set(values)
      expect { subject.swap(1, 4) }
        .to change { subject.to_a }.to contain_exactly(2, 3, 4)
    end
  end

  describe '#clear' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }

    context 'with values' do
      before do
        subject.parent << [subject.parent.rdf_subject,
                           subject.predicate,
                           'moomin']
      end

      it 'clears the relation' do
        expect { subject.clear }
          .to change { subject.to_a }
          .from(['moomin']).to(be_empty)
      end

      it 'deletes statements from parent' do
        query_pattern = [subject.parent.rdf_subject, subject.predicate, nil]

        expect { subject.clear }
          .to change { subject.parent.query(query_pattern) }.to([])
      end

      it 'notifies observers of changed state' do
        observer = double(:observer)
        parent_resource.add_observer(observer)

        expect(observer)
          .to receive(:notify)
          .with(subject.property, be_empty)

        subject.clear
      end
    end

    it 'is a no-op when relation is empty' do
      subject.parent << [subject.parent.rdf_subject, RDF.type, 'moomin']
      expect { subject.clear }.not_to change { subject.parent.statements.to_a }
    end

    it 'does not notify observers when relation is empty' do
      observer = double(:observer)
      parent_resource.add_observer(observer)

      expect(observer).not_to receive(:notify)

      subject.clear
    end
  end

  describe '#<<' do
    include_context 'with symbol property'

    let(:parent_resource) { ActiveTriples::Resource.new }

    it 'adds a value' do
      expect { subject << :moomin }
        .to change { subject.to_a }.to contain_exactly(:moomin)
    end

    it 'adds multiple values' do
      values = [:moomin, :snork]
      expect { subject << values }
        .to change { subject.to_a }.to contain_exactly(*values)
    end

    it 'notifies observers on the parent' do
      observer = double(:observer)
      values   = [:moomin, :snork]
      parent_resource.add_observer(observer)

      expect(observer)
        .to receive(:notify)
        .with(subject.property,
              a_collection_containing_exactly(*values))

      subject << values
    end

    it 'keeps datatypes' do
      values = [RDF::Literal(Date.today), RDF::Literal(:moomin)]

      expect { values.each { |v| subject << v } }
        .to change { subject.send(:objects).to_a }
             .to contain_exactly(*values)
    end

    it 'keeps languages' do
      values = [RDF::Literal("Moomin", language: :en),
                RDF::Literal("Mummi",  language: :fi)]

      expect { values.each { |v| subject << v } }
        .to change { subject.send(:objects).to_a }
             .to contain_exactly(*values)
    end

    context 'when given a Relation' do
      it 'keeps datatypes and languages of values' do
        values = [RDF::Literal(Date.today),
                  RDF::Literal(:moomin),
                  RDF::Literal("Moomin", language: :en),
                  RDF::Literal("Mummi",  language: :fi)]

        subject.set(values)
        expect(subject.send(:objects)).to contain_exactly(*values)

        expect { subject << subject }
          .not_to change { subject.send(:objects).to_a }
      end

      it 'retains unknown datatypes' do
        literal =
          RDF::Literal('snowflake',
                       datatype: RDF::URI('http://emaple.com/snowflake'))

        subject << literal

        expect { subject << 'snowflake' }
          .to change { subject.to_a }
               .to contain_exactly(literal, 'snowflake')

      end

      context 'with a datatyped literal' do
        before do
          class DummySnowflake < RDF::Literal
            DATATYPE = RDF::URI('http://example.com/snowflake').freeze
          end
        end

        after { Object.send(:remove_const, :DummySnowflake) }

        it 'retains datatypes' do
          literal = DummySnowflake.new('special')

          subject << literal

          expect { subject << 'special' }
            .to change { subject.send(:objects).to_a }
                 .to contain_exactly(literal, RDF::Literal('special'))
        end
      end
    end
  end

  describe '#predicate' do
    context 'when the property is an RDF::Term' do
      include_context 'with URI property'

      it 'returns the specified RDF::Term' do
        expect(subject.predicate).to eq uri
      end
    end

    context 'when the property is a symbol' do
      include_context 'with symbol property'

      it 'returns the reflected property' do
        expect(subject.predicate).to eq uri
      end
    end

    context 'when the symbol property is unregistered' do
      include_context 'with unregistered property'

      it 'returns nil' do
        expect(subject.predicate).to be_nil
      end
    end
  end

  describe '#property' do
    context 'when the property is an RDF::Term' do
      include_context 'with URI property'

      it 'returns the specified RDF::Term' do
        expect(subject.property).to eq property
      end
    end

    context 'when the property is a symbol' do
      include_context 'with symbol property'

      it 'returns the property symbol' do
        expect(subject.property).to eq property
      end
    end

    context 'when the symbol property is unregistered' do
      include_context 'with unregistered property'

      it 'returns the property symbol' do
        expect(subject.property).to eq property
      end
    end
  end

  describe '#each' do
    context 'with nil predicate' do
      include_context 'with unregistered property'

      it 'is empty' do
        expect(subject.each.to_a).to be_empty
      end
    end

    context 'with predicate' do
      include_context 'with symbol property' do
        let(:parent_resource) { ActiveTriples::Resource.new }
      end

      it 'is empty' do
        expect(subject.each.to_a).to be_empty
      end

      context 'with values' do
        before do
          values.each do |value|
            subject.parent << [subject.parent.rdf_subject, uri, value]
          end
        end

        let(:values) { ['Comet in Moominland', 'Finn Family Moomintroll'] }
        let(:node)   { RDF::Node.new }

        it 'contain values' do
          expect(subject.each).to contain_exactly(*values)
        end

        context 'with castable values' do
          let(:values) do
            [uri, RDF::URI('http://ex.org/too-ticky'), RDF::Node.new]
          end

          it 'casts Resource values' do
            expect(subject.each)
              .to contain_exactly(a_kind_of(ActiveTriples::Resource),
                                  a_kind_of(ActiveTriples::Resource),
                                  a_kind_of(ActiveTriples::Resource))
          end

          it 'cast values have correct URI' do
            expect(subject.each.map(&:rdf_subject))
              .to contain_exactly(*values)
          end

          context 'and a class is configured' do
            let(:this_type) { RDF::URI('http://example.org/Moomin') }
            let(:this_class) do
              Class.new do
                include ActiveTriples::RDFSource
                configure type: RDF::URI('http://example.org/Moomin')
              end
            end

            let(:other_type) { RDF::URI('http://example.org/Snork') }
            let(:other_class) do
              Class.new do
                include ActiveTriples::RDFSource
                configure type: RDF::URI('http://example.org/Snork')
              end
            end

            before do
              reflections
                .property property,
                          class_name: this_class,
                          predicate:  RDF::URI('http://example.org/moomin')
            end

            it 'casts values with no type to the class' do
              expect(subject).to contain_exactly(an_instance_of(this_class),
                                                 an_instance_of(this_class),
                                                 an_instance_of(this_class))
            end

            it 'casts values with other type to the other class' do
              subject << other_class.new
              expect(subject).to contain_exactly(an_instance_of(this_class),
                                                 an_instance_of(this_class),
                                                 an_instance_of(this_class),
                                                 an_instance_of(other_class))
            end
          end

          context 'and persistence_strategy is configured' do
            context 'as a repository strategy' do
              before do
                reflections
                  .property :moomin,
                            predicate: RDF::URI('http://example.org/moomin'),
                            persist_to: ActiveTriples::RepositoryStrategy
              end

              it 'assigns persistence strategy' do
                subject.each do |node|
                  expect(node.persistence_strategy)
                    .to be_a ActiveTriples::RepositoryStrategy
                end
              end
            end

            context 'as a parent strategy' do
              before do
                reflections
                  .property :moomin,
                            predicate: RDF::URI('http://example.org/moomin'),
                            persist_to: ActiveTriples::ParentStrategy
              end

              it 'assigns persistence strategy' do
                subject.each do |node|
                  expect(node.persistence_strategy)
                    .to be_a ActiveTriples::ParentStrategy
                end
              end

              it 'assigns parent' do
                subject.each do |node|
                  expect(node.persistence_strategy.parent).to eql subject.parent
                end
              end
            end
          end

          context 'and #cast? is false' do
            let(:values) do
              [uri, RDF::URI('http://ex.org/too-ticky'), RDF::Node.new,
               'moomin', Date.today]
            end

            it 'does not cast results' do
              allow(subject).to receive(:cast?).and_return(false)
              expect(subject.each).to contain_exactly(*values)
            end
          end
        end
      end
    end
  end

  describe '#rdf_subject' do
    let(:parent_resource) { double('parent resource', reflections: {}) }

    subject { described_class.new(parent_resource, double('value args')) }

    context 'when relation has 0 value arguments' do
      before { subject.value_arguments = double(length: 0) }

      it 'should raise an error' do
        expect { subject.send(:rdf_subject) }.to raise_error ArgumentError
      end
    end

    context 'when term has 1 value argument' do
      before do
        allow(subject.parent).to receive(:rdf_subject) { 'parent subject' }
        subject.value_arguments = double(length: 1)
      end

      it "should call `rdf_subject' on the parent" do
        expect(subject.send(:rdf_subject)).to eq 'parent subject'
      end

      it 'is a private method' do
        expect { subject.rdf_subject }.to raise_error NoMethodError
      end
    end

    context 'when relation has 2 value arguments' do
      before { subject.value_arguments = double(length: 2, first: 'first') }

      it 'should return the first value argument' do
        expect(subject.send(:rdf_subject)).to eq 'first'
      end
    end

    context 'when relation has 3 value arguments' do
      before { subject.value_arguments = double(length: 3) }

      it 'should raise an error' do
        expect { subject.send(:rdf_subject) }.to raise_error ArgumentError
      end
    end
  end

  describe '#size' do
    context 'with predicate' do
      include_context 'with symbol property' do
        let(:parent_resource) { ActiveTriples::Resource.new }
      end

      context 'with values' do
        let(:values) { ['Comet in Moominland', 'Finn Family Moomintroll'] }
        before do
          values.each do |value|
            subject.parent << [subject.parent.rdf_subject, uri, value]
          end
        end

        it 'returns the size of the result' do
          expect(subject.size).to eq 2
        end

        it 'is aliased by #length' do
          expect(subject.length).to eq 2
        end
      end
    end
  end

  describe '#set' do
    include_context 'with unregistered property'

    it 'raises UndefinedPropertyError' do
      expect { subject.set('x') }
        .to raise_error ActiveTriples::UndefinedPropertyError
    end

    context 'with predicate' do
      include_context 'with symbol property' do
        let(:parent_resource) { ActiveTriples::Resource.new }
      end

      it 'sets a value' do
        expect { subject.set(:moomin) }
          .to change { subject.to_a }.to contain_exactly(:moomin)
      end

      it 'sets mulitple values' do
        values = [:moomin, :snork]
        expect { subject.set(values) }
          .to change { subject.to_a }.to contain_exactly(*values)
      end

      it 'notifies observers on the parent' do
        observer = double(:observer)
        values   = [:moomin, :snork]
        parent_resource.add_observer(observer)

        expect(observer)
          .to receive(:notify)
          .with(subject.property, a_collection_containing_exactly(*values))

        subject.set(values)
      end

      context 'when given a Relation' do
        before do
          class DummySnowflake < RDF::Literal
            DATATYPE = RDF::URI('http://example.com/snowflake').freeze
          end
        end

        after { Object.send(:remove_const, :DummySnowflake) }

        it 'keeps datatypes and languages of values' do
          values = [Date.today,
                    'Moomin',
                    :moomin,
                    RDF::Literal("Moomin", language: :en),
                    RDF::Literal("Mummi",  language: :fi),
                    RDF::Literal("Moomin", datatype: RDF::URI('custom')),
                    DummySnowflake.new('Moomin')]

          subject.set(values)

          values[6] = 'Moomin' # cast known datatypes
          expect(subject.to_a).to contain_exactly(*values)

          expect { subject.set(subject) }
            .not_to change { subject.send(:objects).to_a }
        end
      end

      context 'and persistence config' do
        before do
          reflections
            .property :moomin,
                      predicate: RDF::URI('http://example.org/moomin'),
                      persist_to: ActiveTriples::RepositoryStrategy
        end

        it 'returns values with persistence strategy set' do
          expect(subject.set(RDF::Node.new).map(&:persistence_strategy))
            .to contain_exactly(
              an_instance_of(ActiveTriples::RepositoryStrategy)
            )
        end
      end
    end
  end

  describe '#join' do
    context 'with predicate' do
      include_context 'with symbol property' do
        let(:parent_resource) { ActiveTriples::Resource.new }
      end

      context 'with values' do
        let(:values) { ['Comet in Moominland', 'Finn Family Moomintroll'] }

        before do
          values.each do |value|
            subject.parent << [subject.parent.rdf_subject, uri, value]
          end
        end

        it 'returns joined strings' do
          expect(subject.join(', ')).to satisfy do |v|
            v.split(', ').include?('Comet in Moominland') &&
              v.split(', ').include?('Finn Family Moomintroll')
          end
        end
      end
    end
  end

  describe '#valid_datatype?' do
    before do
      allow(subject.parent).to receive(:rdf_subject) { 'parent subject' }
    end

    subject { described_class.new(double('parent', reflections: []), 'value') }

    context 'the value is not a Resource' do
      it 'should be true if value is a String' do
        expect(subject.send(:valid_datatype?, 'foo')).to be true
      end

      it 'should be true if value is a Symbol' do
        expect(subject.send(:valid_datatype?, :foo)).to be true
      end

      it 'should be true if the value is a Numeric' do
        expect(subject.send(:valid_datatype?, 1)).to   be true
        expect(subject.send(:valid_datatype?, 0.1)).to be true
      end

      it 'should be true if the value is a Date' do
        expect(subject.send(:valid_datatype?, Date.today)).to be true
      end

      it 'should be true if the value is a Time' do
        expect(subject.send(:valid_datatype?, Time.now)).to be true
      end

      it 'should be true if the value is a boolean' do
        expect(subject.send(:valid_datatype?, false)).to be true
        expect(subject.send(:valid_datatype?, true)).to  be true
      end
    end

    context 'the value is a Resource' do
      after { Object.send(:remove_const, :DummyResource) }

      let(:resource) { DummyResource.new }

      context 'and the resource class does not include RDF::Isomorphic' do
        before { class DummyResource; include ActiveTriples::RDFSource; end }

        it 'should be false' do
          expect(subject.send(:valid_datatype?, resource)).to be false
        end
      end

      context 'and the resource class includes RDF:Isomorphic' do
        before do
          class DummyResource
            include ActiveTriples::RDFSource
            include RDF::Isomorphic
          end
        end

        it 'should be false' do
          expect(subject.send(:valid_datatype?, resource)).to be false
        end
      end

      context 'and aliases #== to #isomorphic_with?' do
        before do
          class DummyResource
            include ActiveTriples::RDFSource
            include RDF::Isomorphic

            alias == isomorphic_with?
          end
        end

        it 'should be false' do
          expect(subject.send(:valid_datatype?, resource)).to be false
        end
      end
    end
  end
end
