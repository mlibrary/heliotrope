require 'spec_helper'

describe Hydra::Works::ContainedFiles do
  let(:file_set) { Hydra::Works::FileSet.create }
  let(:pcdm_thumbnail_uri) { ::RDF::URI('http://pcdm.org/use#ThumbnailImage') }

  describe '#thumbnail' do
    context 'when a thumbnail is present' do
      before do
        original_file = file_set.build_thumbnail
        original_file.content = 'thumbnail'
      end
      subject { file_set.thumbnail }
      it 'can be saved without errors' do
        expect(subject.save).to be_truthy
      end
      it 'retrieves content of the thumbnail' do
        expect(subject.content).to eql 'thumbnail'
      end
      it 'retains origin pcdm.File RDF type' do
        expect(subject.metadata_node.type).to include(::RDF::URI('http://pcdm.org/use#ThumbnailImage'))
        expect(subject.metadata_node.type).to include(Hydra::PCDM::Vocab::PCDMTerms.File)
      end
    end

    context 'when building new thumbnail' do
      subject { file_set.build_thumbnail }
      it 'initializes an unsaved File object with Thumbnail type' do
        expect(subject).to be_new_record
        expect(subject.metadata_node.type).to include(pcdm_thumbnail_uri)
        expect(subject.metadata_node.type).to include(Hydra::PCDM::Vocab::PCDMTerms.File)
      end
    end
  end

  describe '#original_file' do
    context 'when an original file is present' do
      before do
        original_file = file_set.build_original_file
        original_file.content = 'original_file'
      end
      subject { file_set.original_file }

      it 'can be saved without errors' do
        expect(subject.save).to be_truthy
      end
      it 'retrieves content of the original_file as a PCDM File' do
        expect(subject.content).to eql 'original_file'
        expect(subject).to be_instance_of Hydra::PCDM::File
      end
      it 'retains origin pcdm.File RDF type' do
        expect(subject.metadata_node.type).to include(::RDF::URI('http://pcdm.org/use#OriginalFile'))
        expect(subject.metadata_node.type).to include(Hydra::PCDM::Vocab::PCDMTerms.File)
      end
    end

    context 'when building original file' do
      subject { file_set.build_original_file }
      it 'initializes an unsaved File object with OrignalFile type' do
        expect(subject).to be_new_record
        expect(subject.metadata_node.type).to include(::RDF::URI('http://pcdm.org/use#OriginalFile'))
        expect(subject.metadata_node.type).to include(Hydra::PCDM::Vocab::PCDMTerms.File)
      end
    end
  end

  describe '#extracted_text' do
    context 'when extracted text is present' do
      before do
        extracted_text = file_set.build_extracted_text
        extracted_text.content = 'extracted_text'
      end
      subject { file_set.extracted_text }
      it 'can be saved without errors' do
        expect(subject.save).to be_truthy
      end
      it 'retrieves content of the extracted_text' do
        expect(subject.content).to eql 'extracted_text'
      end
      it 'retains origin pcdm.File RDF type' do
        expect(subject.metadata_node.type).to include(::RDF::URI('http://pcdm.org/use#ExtractedText'))
        expect(subject.metadata_node.type).to include(Hydra::PCDM::Vocab::PCDMTerms.File)
      end
    end

    context 'when building new extracted text object' do
      subject { file_set.build_extracted_text }
      it 'initializes an unsaved File object with ExtractedText type' do
        expect(subject).to be_new_record
        expect(subject.metadata_node.type).to include(::RDF::URI('http://pcdm.org/use#ExtractedText'))
        expect(subject.metadata_node.type).to include(Hydra::PCDM::Vocab::PCDMTerms.File)
      end
    end
  end
end
