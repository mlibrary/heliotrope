# frozen_string_literal: true
require "spec_helper"
require 'rdf/spec/transaction'
require 'active_triples/util/buffered_transaction'

describe ActiveTriples::BufferedTransaction do
  subject { described_class.new(repository, mutable: true) }

  let(:repository) { RDF::Repository.new }

  shared_context 'with a subject' do
    subject do
      described_class
        .new(repository, mutable: true, subject: term, ancestors: [ancestor])
    end

    let(:term)     { RDF::URI('http://example.com/mummi') }
    let(:ancestor) { RDF::URI('http://example.com/moomin_papa') }

    let(:included_statements) do
      [RDF::Statement(term, RDF::URI('p1'), 'o'),
       RDF::Statement(term, RDF::URI('p2'), 0),
       RDF::Statement(term, RDF::URI('p3'), :o),
       RDF::Statement(:o,   RDF::URI('p4'), ancestor)]
    end

    let(:excluded_statements) do
      [RDF::Statement(RDF::URI('s1'), RDF::URI('p1'), 'o'),
       RDF::Statement(:s2,            RDF::URI('p2'), 0),
       RDF::Statement(:s3,            RDF::URI('p3'), :o),
       RDF::Statement(ancestor,       RDF::URI('p4'), :o)]
    end
  end

  shared_examples 'a buffered changeset' do
    let(:st) { RDF::Statement(:s, RDF::URI('p'), 'o') }

    it 'adds inserts' do
      expect { subject.insert(st) }
        .to change { subject.changes.inserts }.to contain_exactly(st)
    end

    it 'removes deletes when inserting' do
      subject.delete(st)

      expect { subject.insert(st) }
        .to change { subject.changes.deletes }.to be_empty
    end

    it 'adds deletes' do
      expect { subject.delete(st) }
        .to change { subject.changes.deletes }.to contain_exactly(st)
    end

    it 'removes inserts when deleting' do
      subject.insert(st)

      expect { subject.delete(st) }
        .to change { subject.changes.inserts }.to be_empty
    end
  end

  shared_examples 'an optimist' do; end

  # @see lib/rdf/spec/transaction.rb in rdf-spec
  it_behaves_like 'an RDF::Transaction', ActiveTriples::BufferedTransaction

  it_behaves_like 'a buffered changeset'
  it_behaves_like 'an optimist'

  it 'supports snapshots' do
    expect(subject.supports?(:snapshots)).to be true
  end

  it 'is :repeatable_read' do
    expect(subject.isolation_level).to eq :repeatable_read
  end

  describe '#snapshot' do
    it 'returns its current internal state' 
  end

  describe '#each' do
    context 'when projecting' do
      include_context 'with a subject'

      before do
        subject.insert(*included_statements)
        subject.insert(*excluded_statements)
      end

      it 'projects over a bounded description' do
        expect(subject).to contain_exactly(*included_statements)
      end
    end
  end

  describe '#data' do
    it 'returns itself' do
      expect(subject.data).to eq subject
    end
  end

  # This API changed. Need to rework these tests for the RDFSource as Repository case
  # context 'with trasaction as repository' do
  #   subject { described_class.new(repository, mutable: true) }
  #   let(:repository) { described_class.new(RDF::Repository.new, mutable: true) }

  #   it_behaves_like 'a buffered changeset'
  #   it_behaves_like 'an optimist'
    
  #   describe '#execute' do
  #     it 'does not reflect changes to parent' do
  #       st = [:s, RDF::URI(:p), 'o']
  #       expect { repository.insert(st) }.not_to change { subject.statements }
  #     end

  #     it 'does not executed changes to parent' do
  #       st = [:s, RDF::URI(:p), 'o']
  #       expect { repository.insert(st); repository.execute }
  #         .not_to change { subject.statements }
  #     end
      
  #     context 'with no changes' do
  #       it 'leaves parent tx unchanged' do
  #         expect { subject.execute }.not_to change { repository.statements }
  #       end

  #       it 'leaves parent tx insert buffer unchanged' do
  #         expect { subject.execute }.not_to change { repository.changes.inserts }
  #       end

  #       it 'leaves parent tx delete buffer unchanged' do
  #         expect { subject.execute }.not_to change { repository.changes.deletes }
  #       end

  #       it 'leaves top level repository unchanged' do
  #         expect { subject.execute }
  #           .not_to change { repository.repository.statements }
  #       end
  #     end

  #     context 'with changes' do
  #       let(:ins) { RDF::Statement(:ins, RDF::URI('p'), 'o') }
  #       let(:del) { RDF::Statement(:del, RDF::URI('p'), 'o') }
        
  #       before do
  #         subject.insert(ins)
  #         subject.delete(del)
  #       end

  #       it 'adds to parent tx insert buffer' do
  #         expect { subject.execute }
  #           .to change { repository.changes.inserts }.to contain_exactly(ins)
  #       end

  #       it 'adds to parent tx delete buffer' do
  #         expect { subject.execute }
  #           .to change { repository.changes.deletes }.to contain_exactly(del)
  #       end

  #       it 'mutates parent statements' do
  #         repository.insert(del)

  #         expect { subject.execute }
  #           .to change { repository.statements }
  #                .from(contain_exactly(del))
  #                .to contain_exactly(ins)
  #       end

  #       context 'and parent is committed' do
  #         before do
  #           repository.insert(del)
  #           repository.execute
  #         end

  #         it 'mutates parent statements' do
  #           expect { subject.execute }
  #             .to change { repository.statements }
  #                  .from(contain_exactly(del))
  #                  .to contain_exactly(ins)
  #         end
  #       end
  #     end
  #   end
  # end
end
