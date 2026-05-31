# frozen_string_literal: true

RSpec.describe MinterState, type: :model do
  include MinterStateHelper
  before { reset_minter_state_table }
  after { reset_minter_state_table }

  let(:state) { described_class.new }
  let(:first) { described_class.first }

  it 'db is seeded with first row' do
    expect { first }.not_to raise_error
    expect(first.namespace).to eq 'default'
    expect(first.template).to eq '.reeddeeddk'
    expect(first.seq).to eq 0
    expect(described_class.group(:namespace).count).to eq('default' => 1)
  end
  describe 'validation' do
    it 'blocks invalid template' do
      expect { state.save! }.to raise_error(ActiveRecord::RecordInvalid) # empty
      state.template = 'bad_template'
      expect { state.save! }.to raise_error(ActiveRecord::RecordInvalid)
      state.template = 'reeddddk' # close, but missing '.'
      expect { state.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
    it 'allows valid template (edit)' do
      first.template = '.reeddddk'
      expect { first.save! }.not_to raise_error # OK!
    end
    it 'blocks new record in same namespace' do
      state.template = '.reeddddk'
      expect { state.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
    it 'allows new record in distinct namespace' do
      state.template = '.reeddddk'
      state.namespace = 'foobar'
      expect { state.save! }.not_to raise_error # OK!
      expect(described_class.group(:namespace).count).to eq('default' => 1, 'foobar' => 1)
    end
  end
end
