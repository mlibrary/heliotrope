require 'spec_helper'

describe Hydra::Works do
  let(:works_coll)   { Hydra::Works::Collection.new }
  let(:works_gwork)  { Hydra::Works::Work.new }
  let(:file_set)     { Hydra::Works::FileSet.new }

  let(:pcdm_coll)  { Hydra::PCDM::Collection.new }
  let(:pcdm_obj)   { Hydra::PCDM::Object.new }
  let(:pcdm_file)  { Hydra::PCDM::File.new }

  describe 'Validations' do
    describe '#collection?' do
      it 'returns true for a works collection' do
        expect(works_coll.collection?).to be true
      end

      it 'returns false for a works work' do
        expect(works_gwork.collection?).to be false
      end

      it 'returns false for a works file set' do
        expect(file_set.collection?).to be false
      end
    end

    describe '#work?' do
      it 'returns false for a collection' do
        expect(works_coll.work?).to be false
      end

      it 'returns true for a work' do
        expect(works_gwork.work?).to be true
      end

      it 'returns false for a file set' do
        expect(file_set.work?).to be false
      end
    end

    describe '#file_set?' do
      it 'returns false for a works collection' do
        expect(works_coll.file_set?).to be false
      end

      it 'returns false for a works work' do
        expect(works_gwork.file_set?).to be false
      end

      it 'returns true for a works file set' do
        expect(file_set.file_set?).to be true
      end
    end
  end

  describe 'Hydra::PCDM' do
    describe '#collection?' do
      it 'returns true for a works collection' do
        expect(Hydra::PCDM.collection?(works_coll)).to be true
      end

      it 'returns false for a works work' do
        expect(Hydra::PCDM.collection?(works_gwork)).to be false
      end

      it 'returns false for a works file set' do
        expect(Hydra::PCDM.collection?(file_set)).to be false
      end

      it 'returns true for a pcdm collection' do
        expect(Hydra::PCDM.collection?(pcdm_coll)).to be true
      end

      it 'returns false for a pcdm object' do
        expect(Hydra::PCDM.collection?(pcdm_obj)).to be false
      end

      it 'returns false for a pcdm file' do
        expect(Hydra::PCDM.collection?(pcdm_file)).to be false
      end
    end

    describe '#object?' do
      it 'returns false for a works collection' do
        expect(Hydra::PCDM.object?(works_coll)).to be false
      end

      it 'returns true for a works work' do
        expect(Hydra::PCDM.object?(works_gwork)).to be true
      end

      it 'returns true for a works file set' do
        expect(Hydra::PCDM.object?(file_set)).to be true
      end

      it 'returns false for a pcdm collection' do
        expect(Hydra::PCDM.object?(pcdm_coll)).to be false
      end

      it 'returns true for a pcdm object' do
        expect(Hydra::PCDM.object?(pcdm_obj)).to be true
      end

      it 'returns false for a pcdm file' do
        expect(Hydra::PCDM.object?(pcdm_file)).to be false
      end
    end
  end

  describe '::default_system_virus_scanner' do
    subject { described_class.default_system_virus_scanner }
    it { is_expected.to eq(Hydra::Works::VirusScanner) }
  end
end
