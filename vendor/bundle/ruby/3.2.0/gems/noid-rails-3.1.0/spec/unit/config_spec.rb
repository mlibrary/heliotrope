# frozen_string_literal: true

RSpec.describe Noid::Rails::Config do
  subject { described_class.new }

  it { is_expected.to respond_to(:template) }
  it { is_expected.to respond_to(:statefile) }
  it { is_expected.to respond_to(:namespace) }
  it { is_expected.to respond_to(:minter_class) }
  it { is_expected.to respond_to(:identifier_in_use) }

  describe '#template' do
    let(:default) { '.reeddeeddk' }

    it 'has a default' do
      expect(subject.template).to eq default
    end

    describe 'overriding' do
      before { subject.template = custom_template }

      let(:custom_template) { '.dddddd' }

      it 'allows setting a custom template' do
        expect(subject.template).to eq custom_template
      end
    end
  end

  describe '#minter_class' do
    let(:default) { Noid::Rails::Minter::File }

    it 'has a default' do
      expect(subject.minter_class).to eq default
    end

    context 'when overridden' do
      before { subject.minter_class = different_minter }
      let(:different_minter) { Noid::Rails::Minter::File }

      it 'uses the different minter' do
        expect(subject.minter_class).to eq different_minter
      end
    end
  end

  describe '#identifier_in_use' do
    it 'defaults to always return false' do
      expect(subject.identifier_in_use.call('NEW_ID')).to be false
      expect(subject.identifier_in_use.call('EXISTING_ID')).to be false
    end

    context 'when overridden' do
      let(:override_check) do
        lambda do |id|
          return true if id == 'EXISTING_ID'
          false
        end
      end

      before { subject.identifier_in_use = override_check }

      it 'returns false if id does not exist' do
        expect(subject.identifier_in_use.call('NEW_ID')).to be false
      end

      it 'returns true if id exists' do
        expect(subject.identifier_in_use.call('EXISTING_ID')).to be true
      end
    end
  end
end
