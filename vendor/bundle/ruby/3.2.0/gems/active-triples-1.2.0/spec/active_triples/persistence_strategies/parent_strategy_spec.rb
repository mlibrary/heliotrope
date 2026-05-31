# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::ParentStrategy do
  subject { described_class.new(rdf_source) }
  let(:rdf_source) { BasicPersistable.new }

  shared_context 'with a parent' do
    subject      { rdf_source.persistence_strategy }
    let(:parent) { BasicPersistable.new }

    before do
      rdf_source.set_persistence_strategy(described_class)
      rdf_source.persistence_strategy.parent = parent
    end
  end

  context 'with a parent' do
    include_context 'with a parent'
    it_behaves_like 'a persistence strategy'

    describe '#persisted?' do
      context 'before persist!' do
        it 'returns false' do
          expect(subject).not_to be_persisted
        end
      end

      context 'after persist!' do
        context "when the parent is not persisted" do
          before { subject.persist! }
          it { is_expected.not_to be_persisted }
        end

        context "when the parent is persisted" do
          before do
            allow(parent).to receive(:persisted?).and_return(true)
            subject.persist!
          end
          it { is_expected.to be_persisted }
        end
      end
    end
  end

  describe '#destroy' do
    include_context 'with a parent'

    before do
      rdf_source.insert(*statements)
      subject.persist!
    end

    let(:statements) do
      [RDF::Statement(subject.source.rdf_subject, RDF::Vocab::DC.title, 'moomin'),
       RDF::Statement(subject.parent, RDF::Vocab::DC.relation, subject.source.rdf_subject)]
    end

    it 'removes graph from the parent' do
      subject.destroy

      statements.each do |statement|
        expect(subject.parent.statements).not_to have_statement statement
      end
    end

    it 'removes subjects from parent' do
      subject.destroy
      expect(subject.parent).not_to have_subject(rdf_source)
    end

    it 'removes objects from parent' do
      subject.destroy
      expect(subject.parent).not_to have_object(rdf_source)
    end
  end

  describe '#ancestors' do
    it 'raises NilParentError when enumerating' do
      expect { subject.ancestors.next }
        .to raise_error described_class::NilParentError
    end

    context 'with parent' do
      include_context 'with a parent'

      it 'gives the parent' do
        expect(subject.ancestors).to contain_exactly(parent)
      end

      context 'and nested parents' do
        let(:parents) do
          [double('second', persistence_strategy: double('strategy2')),
           double('third', persistence_strategy: double('strategy3'))]
        end
        let(:last) { double('last', persistence_strategy: double('last_strategy')) }

        it 'gives all ancestors' do
          allow(parent.persistence_strategy)
            .to receive(:parent).and_return(parents.first)
          allow(parents.first.persistence_strategy)
            .to receive(:parent).and_return(parents[1])
          allow(parents[1].persistence_strategy)
            .to receive(:parent).and_return(last)

          expect(subject.ancestors)
            .to contain_exactly(*(parents << parent << last))
        end
      end
    end
  end

  describe '#final_parent' do
    it 'raises an error with no parent' do
      expect { subject.final_parent }
        .to raise_error described_class::NilParentError
    end

    context 'with single parent' do
      include_context 'with a parent'

      it 'gives parent' do
        expect(subject.final_parent).to eq subject.parent
      end
    end

    context 'with parent chain' do
      include_context 'with a parent'
      let(:last) { double('last', persistence_strategy: nil) }

      it 'gives last parent terminating when no futher parents given' do
        allow(parent.persistence_strategy).to receive(:parent).and_return(last)
        expect(subject.final_parent).to eq last
      end

      it 'gives last parent terminating parent is nil' do
        allow(parent.persistence_strategy).to receive(:parent).and_return(last)
        expect(subject.final_parent).to eq last
      end

      it 'gives last parent terminating parent is same as current' do
        allow(parent.persistence_strategy).to receive(:parent).and_return(last)
        expect(subject.final_parent).to eq last
      end
    end
  end

  describe '#parent' do
    it { is_expected.to have_attributes(:parent => nil) }

    context 'with a parent' do
      include_context 'with a parent'
      it { is_expected.to have_attributes(:parent => parent) }
    end
  end

  describe '#parent=' do
    it 'requires a non-nil value' do
      expect { subject.parent = nil }
        .to raise_error described_class::NilParentError
    end

    it 'requires the value to be RDF::Mutable' do
      expect { subject.parent = Object.new }
        .to raise_error described_class::UnmutableParentError
    end

    it 'requires its parent to be #mutable?' do
      immutable = double
      allow(immutable).to receive(:mutable?).and_return(false)
      expect { subject.parent = immutable }
        .to raise_error described_class::UnmutableParentError
    end
  end

  describe '#persist!' do
    it 'raises an error with no parent' do
      expect { subject.persist! }.to raise_error described_class::NilParentError
    end

    context 'with parent' do
      include_context 'with a parent'

      let(:parent_st) { RDF::Statement(parent,     RDF::URI(:p), rdf_source) }
      let(:child_st)  { RDF::Statement(rdf_source, RDF::URI(:p), 'chld') }

      it 'writes to #parent graph' do
        rdf_source << child_st

        expect { subject.persist! }
          .to change { subject.parent.statements }
               .to contain_exactly *rdf_source.statements
      end

      it 'writes to #parent graph when parent changes while child is live' do
        parent.insert(parent_st)
        parent.persist!

        rdf_source.insert(child_st)

        expect { subject.persist! }
          .to change { parent.statements }
               .from(contain_exactly(parent_st))
               .to(contain_exactly(parent_st, child_st))
      end

      context 'with nested parents' do
        let(:last) { BasicPersistable.new }

        before do
          parent.set_persistence_strategy(ActiveTriples::ParentStrategy)
          parent.persistence_strategy.parent = last
          rdf_source.reload
        end

        it 'writes to #parent graph when parent changes while child is live' do
          parent.insert(parent_st)
          parent.persist!

          rdf_source.insert(child_st)

          expect { subject.persist! }
            .to change { parent.statements }
                 .from(contain_exactly(parent_st))
                 .to(contain_exactly(parent_st, child_st))
        end

        it 'writes to #last graph when persisting' do
          parent.insert(parent_st)
          parent.persist!

          rdf_source.insert(child_st)

          expect { subject.persist!; parent.persist! }
            .to change { last.statements }
                 .from(contain_exactly(parent_st))
                 .to(contain_exactly(parent_st, child_st))
        end
      end
    end
  end
end

describe ActiveTriples::ParentStrategy::Ancestors do
  subject { described_class.new(rdf_source) }

  let(:rdf_source) { BasicPersistable.new }

  describe '#each' do
    it 'raises NilParentError' do
      expect { subject.each }
        .to raise_error ActiveTriples::ParentStrategy::NilParentError
    end

    context 'with parents' do
      let(:parent) { BasicPersistable.new }
      let(:last)   { BasicPersistable.new }

      before do
        parent.set_persistence_strategy(ActiveTriples::ParentStrategy)
        parent.persistence_strategy.parent = last
        rdf_source.set_persistence_strategy(ActiveTriples::ParentStrategy)
        rdf_source.persistence_strategy.parent = parent
      end

      it { expect(subject.each).to be_a Enumerator }

      it 'enumerates ancestors' do
        expect(subject.each).to contain_exactly(parent, last)
      end

      it 'yields ancestors' do
        expect { |b| subject.each(&b) }.to yield_successive_args(parent, last)
      end
    end
  end
end
