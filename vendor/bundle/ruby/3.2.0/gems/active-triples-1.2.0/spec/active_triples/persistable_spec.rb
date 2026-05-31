# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::Persistable do
  subject { klass.new }

  let(:klass) { Class.new { include ActiveTriples::Persistable } }

  let(:statement) do
    RDF::Statement(RDF::Node.new, RDF::Vocab::DC.title, 'Moomin')
  end

  describe 'method delegation' do
    context 'with a strategy' do
      let(:strategy_class) do
        object_double(ActiveTriples::ParentStrategy).as_stubbed_const
      end

      let(:strategy) { instance_double('PersistenceStrategy') }

      before do
        allow(strategy_class).to receive(:new).and_return(strategy)
        subject.set_persistence_strategy(strategy_class)
      end

      describe '#persist!' do
        before { allow(subject).to receive(:run_callbacks).and_yield }

        it 'sends message to strategy' do
          expect(strategy).to receive(:persist!)
          subject.persist!
        end
      end

      describe '#destroy' do
        it 'sends message to strategy' do
          expect(strategy).to receive(:destroy)
          subject.destroy
        end
      end

      describe '#persisted?' do
        it 'sends message to strategy' do
          expect(strategy).to receive(:persisted?)
          subject.persisted?
        end
      end

      describe '#reload' do
        it 'sends message to strategy' do
          expect(strategy).to receive(:reload)
          subject.reload
        end
      end
    end
  end

  describe '#persistence_strategy' do
    it 'defaults to RepositoryStrategy' do
      expect(subject.persistence_strategy)
        .to be_a ActiveTriples::RepositoryStrategy
    end
  end

  describe '#set_persistence_strategy' do
    let(:strategy_class) { double('strategy class') }
    let(:strategy) { double('persistence strategy') }

    before do
      allow(strategy_class).to receive(:new).and_return(strategy)
    end

    it 'sets new persistence strategy as an instance of the given class' do
      expect { subject.set_persistence_strategy(strategy_class) }
        .to change { subject.persistence_strategy }
             .from(an_instance_of(ActiveTriples::RepositoryStrategy))
             .to(strategy)
    end
  end

  context 'with graph implementation' do
    before do
      graph = RDF::Graph.new
      allow(subject).to receive(:graph).and_return(graph)
    end

    it 'mirrors writes to graph' do
      subject << statement
      expect(subject.graph).to contain_exactly statement
    end
  end
end
