# frozen_string_literal: true

RSpec.describe MCSV::Manifest do
  let(:noid) { 'validnoid' }
  let(:non_noid) { 'invalidnoid' }

  # Class Methods

  describe '#clear_cache' do
    it { expect(described_class).to respond_to(:clear_cache) }
  end

  describe '#from' do
    subject { described_class.from(data) }

    context 'non hash' do
      context 'nil' do
        let(:data) { nil }
        it { is_expected.to be_an_instance_of(MCSV::ManifestNullObject) }
      end
      context 'non-noid' do
        let(:data) { non_noid }
        it { is_expected.to be_an_instance_of(MCSV::ManifestNullObject) }
      end
      context 'noid' do
        let(:data) { noid }
        it { is_expected.to be_an_instance_of(described_class) }
      end
    end
    context 'hash' do
      context 'empty' do
        let(:data) { {} }
        it { is_expected.to be_an_instance_of(MCSV::ManifestNullObject) }
      end
      context 'nil' do
        let(:data) { { id: nil } }
        it { is_expected.to be_an_instance_of(MCSV::ManifestNullObject) }
      end
      context 'non-noid' do
        let(:data) { { id: non_noid } }
        it { is_expected.to be_an_instance_of(MCSV::ManifestNullObject) }
      end
      context 'noid' do
        let(:data) { { id: noid } }
        it { is_expected.to be_an_instance_of(described_class) }
      end
    end
  end

  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }
    it { is_expected.to be_an_instance_of(MCSV::ManifestNullObject) }
  end

  # Instance Methods

  describe '#purge' do
    it { expect(described_class.from(noid)).to respond_to(:purge) }
  end
end
