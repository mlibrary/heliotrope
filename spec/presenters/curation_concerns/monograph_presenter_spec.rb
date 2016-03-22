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
    let(:chapter_2_doc) { SolrDocument.new(id: 'chapter2', active_fedora_model_ssi: ['Section']) }
    let(:chapter_3_doc) { SolrDocument.new(id: 'chapter3', active_fedora_model_ssi: ['Section']) }

    before do
      # I added chapter 1 twice to make sure that duplicate
      # entries will work correctly.
      mono_doc.merge!(ordered_member_ids_ssim: [fileset_doc.id, chapter_1_doc.id, chapter_2_doc.id, chapter_3_doc.id, chapter_1_doc.id])
      ActiveFedora::SolrService.add([fileset_doc, chapter_2_doc, chapter_1_doc, chapter_3_doc, mono_doc])
      ActiveFedora::SolrService.commit
    end

    describe '#section_docs' do
      subject { presenter.section_docs }

      it 'finds solr docs for attached sections in the correct order' do
        expect(subject.count).to eq 4
        expect(subject.map(&:class).uniq).to eq [SolrDocument]
        expect(subject.map(&:id)).to eq [chapter_1_doc.id, chapter_2_doc.id, chapter_3_doc.id, chapter_1_doc.id]
      end
    end
  end

  describe '#date_published' do
    before do
      allow(mono_doc).to receive(:date_published).and_return(['Oct 7th'])
    end
    subject { presenter.date_published }
    it { is_expected.to eq ['Oct 7th'] }
  end
end
