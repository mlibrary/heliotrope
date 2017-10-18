# frozen_string_literal: true

RSpec.describe EPub::Cache do
  let(:noid) { 'validnoid' }
  let(:non_noid) { 'invalidnoid' }
  let(:id) { double('id') }

  before { described_class.cache(id, './spec/fixtures/fake_epub01.epub') }
  after { described_class.clear }

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#cache' do
    subject { described_class.cache(id, './spec/fixtures/fake_epub01.epub') }

    context 'non noid' do
      let(:id) { non_noid }
      it do
        expect(described_class.cached?(id)).to be false
        subject
        expect(described_class.cached?(id)).to be false
      end
    end
    context 'noid' do
      let(:id) { noid }
      it do
        expect(described_class.cached?(id)).to be true
        subject
        expect(described_class.cached?(id)).to be true
      end
    end
  end

  describe '#cached?' do
    subject { described_class.cached?(id) }

    context 'non noid' do
      let(:id) { non_noid }
      it { is_expected.to be false }
    end
    context 'noid' do
      let(:id) { noid }
      it { is_expected.to be true }
    end
  end

  describe '#clear' do
    subject { described_class.clear }

    context 'non noid' do
      let(:id) { non_noid }
      it do
        expect(described_class.cached?(id)).to be false
        subject
        expect(described_class.cached?(id)).to be false
      end
    end
    context 'noid' do
      let(:id) { noid }
      it do
        expect(described_class.cached?(id)).to be true
        subject
        expect(described_class.cached?(id)).to be false
      end
    end
  end

  describe '#publication' do
    subject { described_class.publication(id) }

    context 'non noid' do
      let(:id) { non_noid }
      it { is_expected.to be_an_instance_of(EPub::PublicationNullObject) }
    end
    context 'noid' do
      let(:id) { noid }
      it { is_expected.to be_an_instance_of(EPub::Publication) }
    end
  end

  describe '#purge' do
    subject { described_class.purge(id) }

    context 'non noid' do
      let(:id) { non_noid }
      it do
        expect(described_class.cached?(id)).to be false
        subject
        expect(described_class.cached?(id)).to be false
      end
    end
    context 'noid' do
      let(:id) { noid }
      it do
        expect(described_class.cached?(id)).to be true
        subject
        expect(described_class.cached?(id)).to be false
      end
    end
  end
end
