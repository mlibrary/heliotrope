require 'rails_helper'

describe CurationConcerns::MonographPresenter do
  let(:mono_doc) { SolrDocument.new(id: 'mono', active_fedora_model_ssi: ['Monograph']) }
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(mono_doc, ability) }

  context 'a monograph with no attached members' do
    describe '#section_docs' do
      subject { presenter.section_docs }

      it 'returns an empty set' do
        expect(subject).to eq []
      end
    end
  end

  context 'a monograph with sections and filesets' do
    let(:fileset_doc) { SolrDocument.new(id: 'fileset', active_fedora_model_ssi: ['FileSet']) }
    let(:chapter_1_doc) { SolrDocument.new(id: 'chapter1', active_fedora_model_ssi: ['Section']) }

    before do
      mono_doc.merge!(member_ids_ssim: [fileset_doc.id, chapter_1_doc.id])
      ActiveFedora::SolrService.add([fileset_doc, chapter_1_doc, mono_doc])
      ActiveFedora::SolrService.commit
    end

    describe '#section_docs' do
      subject { presenter.section_docs }

      it 'finds solr docs for attached sections' do
        expect(subject.count).to eq 1
        expect(subject.first.class).to eq SolrDocument
        expect(subject.first.id).to eq chapter_1_doc.id
      end
    end
  end
end
