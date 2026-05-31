require 'spec_helper'

describe Hydra::PCDM do
  let(:coll1)  { Hydra::PCDM::Collection.create }
  let(:obj1)   { Hydra::PCDM::Object.create }
  let(:file1)  { Hydra::PCDM::File.new }

  describe 'Validations' do
    describe '#collection?' do
      it 'return true for a pcdm collection' do
        expect(described_class).to be_collection coll1
      end

      it 'return false for a pcdm object' do
        expect(described_class).not_to be_collection obj1
      end

      it 'return false for a pcdm file' do
        expect(described_class).not_to be_collection file1
      end
    end

    describe '#object?' do
      it 'return false for a pcdm collection' do
        expect(described_class).not_to be_object coll1
      end

      it 'return true for a pcdm object' do
        expect(described_class).to be_object obj1
      end

      it 'return false for a pcdm file' do
        expect(described_class).not_to be_object file1
      end
    end

    describe '#file?' do
      it 'return false for a pcdm collection' do
        expect(described_class).not_to be_file coll1
      end

      it 'return false for a pcdm object' do
        expect(described_class).not_to be_file obj1
      end

      it 'return true for a pcdm file' do
        expect(described_class).to be_file file1
      end
    end
  end
end
