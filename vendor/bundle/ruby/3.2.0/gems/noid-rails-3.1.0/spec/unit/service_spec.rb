# frozen_string_literal: true

RSpec.describe Noid::Rails::Service do
  describe 'public API' do
    it { is_expected.to respond_to(:valid?) }
    it { is_expected.to respond_to(:mint) }
  end

  it 'has a default minter' do
    expect(subject.minter).to be_instance_of Noid::Rails::Minter::File
  end

  context 'with a custom minter' do
    let(:minter) { double('minter') }
    let(:identifier) { 'abc123' }
    let(:new_service) { described_class.new(minter) }

    it 'allows injecting a custom minter' do
      expect(new_service.minter).to eq minter
    end

    it 'delegates validity checking to the minter' do
      expect(minter).to receive(:valid?).with(identifier).once
      new_service.valid? identifier
    end

    it 'delegates minting to the minter' do
      expect(minter).to receive(:mint).once
      new_service.mint
    end
  end
end
