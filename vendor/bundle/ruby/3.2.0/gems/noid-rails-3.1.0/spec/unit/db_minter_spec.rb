# frozen_string_literal: true

RSpec.describe Noid::Rails::Minter::Db do
  include MinterStateHelper

  after { reset_minter_state_table }
  subject(:db_minter) { described_class.new }

  before do
    reset_minter_state_table
  end

  it_behaves_like 'a minter' do
    let(:minter) { db_minter }
  end

  describe '#initialize' do
    it 'raises on bad templates' do
      expect { described_class.new('reeddeeddk') }.to raise_error(Noid::TemplateError)
      expect { described_class.new('')           }.to raise_error(Noid::TemplateError)
    end
    it 'returns object w/ default template' do
      expect(db_minter).to be_instance_of described_class
      expect(db_minter).to be_a Noid::Minter
      expect(db_minter.template).to be_instance_of Noid::Template
      expect(db_minter.template.to_s).to eq Noid::Rails.config.template
    end
    context 'with a user provided template' do
      let(:db_minter) { described_class.new('.reedddk') }

      it 'accepts valid template arg' do
        expect(db_minter).to be_instance_of described_class
        expect(db_minter).to be_a Noid::Minter
        expect(db_minter.template).to be_instance_of Noid::Template
        expect(db_minter.template.to_s).to eq '.reedddk'
      end
    end
  end

  describe '#read' do
    subject { db_minter.read }

    context 'when the database has been initialized' do
      it 'has the expected namespace and template' do
        expect(subject).to include(namespace: Noid::Rails.config.namespace,
                                   template: Noid::Rails.config.template)
      end
    end

    context 'when the database has not been initialized' do
      before do
        MinterState.destroy_all
      end
      it 'has the expected namespace and template' do
        expect(subject).to include(namespace: Noid::Rails.config.namespace,
                                   template: Noid::Rails.config.template)
      end
    end
  end

  describe '#write!' do
    let(:starting_state) { db_minter.read }
    let(:minter) { Noid::Minter.new(starting_state) }

    before { minter.mint }

    it 'changes the state of the minter' do
      expect { db_minter.write!(minter) }
        .to change { db_minter.read[:seq] }
        .from(starting_state[:seq]).to(minter.seq)
        .and change { db_minter.read[:counters] }
        .from(starting_state[:counters]).to(minter.counters)
        .and change { db_minter.read[:rand] }
        .from(starting_state[:rand]).to(Marshal.dump(minter.instance_variable_get(:@rand)))
    end
  end

  describe '#next_id' do
    let(:stub_minter) { described_class.new }
    let(:locked) { MinterState }

    it 'locks DB row and does not query twice' do
      expect(MinterState).to receive(:lock).and_return(locked).once
      expect(locked).to receive(:find_by!).once.and_return(MinterState.first)
      stub_minter.send(:next_id)
    end
  end
end
