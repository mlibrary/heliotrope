require 'spec_helper'
autoload :DummyResourceA, 'integration/dummies/dummy_resource_a'
autoload :DummyResourceB, 'integration/dummies/dummy_resource_b'

describe 'reciprocal properties' do
  context 'when using repository strategy for all' do
    before do
      ActiveTriples::Repositories.add_repository :default, RDF::Repository.new
    end

    let (:a) do
      # a = DummyResourceA.new(RDF::URI('http://example.com/a'))
      a = DummyResourceA.new
      a.label = 'resource A'
      a
    end

    let (:b) do
      # b = DummyResourceB.new(RDF::URI('http://example.com/b'))
      b = DummyResourceB.new
      b.label = 'resource B'
      b
    end

    it 'should allow A -> B -> A' do
      expect(a.persistence_strategy).to be_kind_of ActiveTriples::RepositoryStrategy
      expect(b.persistence_strategy).to be_kind_of ActiveTriples::RepositoryStrategy

      a.has_resource = b
      expect(a.has_resource).to eq [b]
      expect(a.label).to be_a_relation_containing('resource A')
      expect(b.label).to be_a_relation_containing('resource B')

      b.in_resource = a
      expect(b.in_resource).to eq [a]
      expect(a.label).to be_a_relation_containing('resource A')
      expect(b.label).to be_a_relation_containing('resource B')
    end
  end

  context 'when using parent_strategy for some' do
    let (:a) do
      d = DummyResourceA.new(RDF::URI('http://example.com/a'))
      d.label = 'resource A'
      d
    end

    let (:b) do
      p = DummyResourceB.new(RDF::URI('http://example.com/b'), a)
      p.label = 'resource B'
      p
    end

    it 'should allow A -> B -> A' do
      expect(a.persistence_strategy).to be_kind_of ActiveTriples::RepositoryStrategy
      expect(b.persistence_strategy).to be_kind_of ActiveTriples::ParentStrategy

      a.has_resource = b
      expect(a.has_resource).to eq [b]
      expect(a.label).to be_a_relation_containing('resource A')
      expect(b.label).to be_a_relation_containing('resource B')

      b.in_resource = a
      expect(b.in_resource).to eq [a]
      expect(a.label).to be_a_relation_containing('resource A')
      expect(b.label).to be_a_relation_containing('resource B')
    end
  end
end
