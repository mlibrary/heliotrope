require 'rails_helper'

describe CurationConcerns::MonographPresenter do
  before { Press.destroy_all }
  let(:press) { create(:press, subdomain: 'michigan') }

  let(:imprint) { create(:sub_brand, title: 'UM Press Literary Classics') }
  let(:series) { create(:sub_brand, title: "W. Shakespeare Collector's Series") }

  let(:mono_doc) { SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph']) }
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(mono_doc, ability) }

  describe '#sub_brand_links' do
    context 'a monograph without sub-brands' do
      let(:mono_doc) { SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], press_tesim: [press.subdomain]) }

      it 'returns empty list' do
        expect(presenter.sub_brand_links).to eq []
      end
    end

    # This case will probably never happen
    context 'when press is missing' do
      let(:mono_doc) { SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], sub_brand_ssim: [imprint.id, series.id]) }

      it 'returns nil' do
        expect(presenter.sub_brand_links).to be_nil
      end
    end

    context 'a monograph with sub-brands' do
      let(:mono_doc) { SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], press_tesim: [press.subdomain], sub_brand_ssim: [imprint.id, series.id]) }

      it 'returns links for the sub-brands' do
        expect(presenter.sub_brand_links.count).to eq 2
        expect(presenter.sub_brand_links.first).to match(/href="#{Rails.application.routes.url_helpers.press_sub_brand_path(press, imprint)}"/)
        expect(presenter.sub_brand_links.last).to match(/href="#{Rails.application.routes.url_helpers.press_sub_brand_path(press, series)}"/)
      end
    end

    context 'when it fails to find the sub-brand' do
      let(:mono_doc) { SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], press_tesim: [press.subdomain], sub_brand_ssim: [imprint.id, series.id]) }

      before { series.destroy } # Now the series ID is invalid

      it 'gracefully ignores missing sub-brands' do
        expect(presenter.sub_brand_links.count).to eq 1
        expect(presenter.sub_brand_links.first).to match(/href="#{Rails.application.routes.url_helpers.press_sub_brand_path(press, imprint)}"/)
      end
    end
  end

  context 'a monograph with no attached members' do
    describe '#section_docs' do
      subject { presenter.section_docs }

      it 'returns an empty set' do
        expect(subject).to eq []
      end
    end
  end

  context 'a monograph with sections and filesets' do
    let(:fileset_doc) { SolrDocument.new(id: 'fileset', has_model_ssim: ['FileSet']) }
    let(:chapter_1_doc) { SolrDocument.new(id: 'chapter1', has_model_ssim: ['Section']) }
    let(:chapter_2_doc) { SolrDocument.new(id: 'chapter2', has_model_ssim: ['Section']) }
    let(:chapter_3_doc) { SolrDocument.new(id: 'chapter3', has_model_ssim: ['Section']) }
    let(:chapter_4_doc) { SolrDocument.new(id: 'chapter4', has_model_ssim: ['Section']) }
    let(:chapter_5_doc) { SolrDocument.new(id: 'chapter5', has_model_ssim: ['Section']) }
    let(:chapter_6_doc) { SolrDocument.new(id: 'chapter6', has_model_ssim: ['Section']) }
    let(:chapter_7_doc) { SolrDocument.new(id: 'chapter7', has_model_ssim: ['Section']) }
    let(:chapter_8_doc) { SolrDocument.new(id: 'chapter8', has_model_ssim: ['Section']) }
    let(:chapter_9_doc) { SolrDocument.new(id: 'chapter9', has_model_ssim: ['Section']) }
    let(:chapter_10_doc) { SolrDocument.new(id: 'chapter10', has_model_ssim: ['Section']) }
    # I added chapter 1 twice to make sure that duplicate
    # entries will work correctly.
    let(:mono_doc) { SolrDocument.new(id: 'mono',
                                      has_model_ssim: ['Monograph'],
                                      ordered_member_ids_ssim: [fileset_doc.id, chapter_1_doc.id, chapter_2_doc.id, chapter_3_doc.id, chapter_1_doc.id, chapter_4_doc.id, chapter_5_doc.id, chapter_6_doc.id, chapter_7_doc.id, chapter_8_doc.id, chapter_9_doc.id, chapter_10_doc.id]) }

    before do
      ActiveFedora::SolrService.add([fileset_doc, chapter_2_doc, chapter_1_doc, chapter_3_doc, mono_doc, chapter_4_doc, chapter_5_doc, chapter_6_doc, chapter_7_doc, chapter_8_doc, chapter_9_doc, chapter_10_doc])
      ActiveFedora::SolrService.commit
    end

    describe '#section_docs' do
      subject { presenter.section_docs }

      it 'finds solr docs for attached sections in the correct order' do
        # Make sure we're testing with more than 10 members
        # to test that we are getting the right number of
        # results back from the solr query.  Default solr
        # query is 10, so if we don't specify the number of
        # rows that we want, we'll be missing some results.
        expect(mono_doc['ordered_member_ids_ssim'].count).to be >= 10
        expect(subject.count).to eq 11
        expect(subject.map(&:class).uniq).to eq [SolrDocument]
        expect(subject.map(&:id)).to eq [chapter_1_doc.id, chapter_2_doc.id, chapter_3_doc.id, chapter_1_doc.id, chapter_4_doc.id, chapter_5_doc.id, chapter_6_doc.id, chapter_7_doc.id, chapter_8_doc.id, chapter_9_doc.id, chapter_10_doc.id]
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
