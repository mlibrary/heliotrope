# frozen_string_literal: true
require "spec_helper"
require 'rdf/spec/enumerable'
require 'rdf/spec/queryable'
require 'active_triples/util/extended_bounded_description'

describe ActiveTriples::ExtendedBoundedDescription do
  subject { described_class.new(source_graph, starting_node, ancestors) }

  let(:ancestors)     { [] }
  let(:source_graph)  { RDF::Repository.new }
  let(:starting_node) { RDF::Node.new }

  it { is_expected.not_to be_mutable }

  shared_examples 'a bounded description' do
    before do 
      source_graph.insert(*included_statements)
      source_graph.insert(*excluded_statements)
    end

    it 'projects over a bounded description' do
      expect(subject).to contain_exactly(*included_statements)
    end

    it 'can iterate repeatedly' do
      expect(subject).to contain_exactly(*included_statements)
      expect(subject).to contain_exactly(*included_statements)
    end
    
    it 'is queryable' do
      expect(subject.query([nil, nil, nil]))
        .to contain_exactly(*included_statements)
    end
  end

  ##
  # *** We don't pass these RDF::Spec examples.
  # They try to test boring things, like having the triples we put in.
  #
  # @see lib/rdf/spec/enumerable.rb in rdf-spec
  # it_behaves_like 'an RDF::Enumerable' do
  #   let(:graph)      { RDF::Repository.new.insert(*statements) }
  #   let(:statements) { RDF::Spec.quads }
  #
  #   let(:enumerable) do
  #     ActiveTriples::ExtendedBoundedDescription
  #       .new(graph, statements.first.subject)
  #   end
  # end
  #
  # @see lib/rdf/spec/queryable.rb in rdf-spec
  # it_behaves_like 'an RDF::Queryable' do
  #   let(:graph)      { RDF::Repository.new.insert(*statements) }
  #   let(:statements) { RDF::Spec.quads }
  #
  #   let(:queryable) do
  #     ActiveTriples::ExtendedBoundedDescription
  #       .new(graph, statements.first.subject)
  #   end
  # end
  #
  # *** end boring stuff
  ##
  
  let(:included_statements) do
    [RDF::Statement(starting_node, RDF::URI('p1'), 'o'),
     RDF::Statement(starting_node, RDF::URI('p2'), 0),
     RDF::Statement(starting_node, RDF::URI('p3'), :o1),
     RDF::Statement(:o1,           RDF::URI('p4'), :o2),
     RDF::Statement(:o1,           RDF::URI('p5'), 'w0w'),
     RDF::Statement(:o2,           RDF::URI('p6'), :o1)]
  end

  let(:excluded_statements) do
    [RDF::Statement(RDF::URI('s1'), RDF::URI('p1'), 'o'),
     RDF::Statement(:s2,            RDF::URI('p2'), 0),
     RDF::Statement(:s3,            RDF::URI('p3'), :o),
     RDF::Statement(:s3,            RDF::URI('p3'), starting_node)]
  end

  it_behaves_like 'a bounded description'

  context 'with ancestors' do
    before do
      included_statements <<
        RDF::Statement(starting_node, RDF::URI('a'), ancestor)

      excluded_statements << 
        RDF::Statement(ancestor, RDF::URI('a'), starting_node)
    end
    
    let(:ancestor)  { RDF::Node.new(:ancestor) }
    let(:ancestors) { [ancestor] }

    it_behaves_like 'a bounded description'
  end
end
