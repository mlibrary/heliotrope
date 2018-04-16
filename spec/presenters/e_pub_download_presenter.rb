# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubDownloadPresenter do
  subject { described_class.new(epub, mono, current_ability) }

  let(:current_ability) { double('current_ability') }

  let(:epub) { Hyrax::FileSetPresenter.new(SolrDocument.new(id: 'epub_id', has_model_ssim: ['FileSet'], file_size_lts: 20_000, allow_download_ssim: 'yes'), current_ability) }
  let(:mono) { Hyrax::MonographPresenter.new(SolrDocument.new(id: 'mono_id', has_model_ssim: ['Monograph']), current_ability) }

  let(:mobi_doc) { SolrDocument.new(id: 'mobi_id', has_model_ssim: ['FileSet'], file_size_lts: 30_000, allow_download_ssim: 'yes') }
  let(:pdfe_doc) { SolrDocument.new(id: 'pdfe_id', has_model_ssim: ['FileSet'], file_size_lts: 40_000, allow_download_ssim: 'yes') }

  let!(:fre) { create(:featured_representative, file_set_id: 'epub_id', monograph_id: 'mono_id', kind: 'epub') }
  let!(:frm) { create(:featured_representative, file_set_id: 'mobi_id', monograph_id: 'mono_id', kind: 'mobi') }
  let!(:frp) { create(:featured_representative, file_set_id: 'pdfe_id', monograph_id: 'mono_id', kind: 'pdf_ebook') }

  before do
    ActiveFedora::SolrService.add([mobi_doc.to_h, pdfe_doc.to_h])
    ActiveFedora::SolrService.commit
  end

  after { FeaturedRepresentative.destroy_all }

  it "has a mobi file size" do
    expect(subject.mobi.file_size).to eq 30_000
  end

  it "has a pdf_ebook file size" do
    expect(subject.pdf_ebook.file_size).to eq 40_000
  end

  it "has download_links" do
    allow(current_ability).to receive(:platform_admin?).and_return(false)
    allow(current_ability).to receive(:can?).and_return(false)

    expect(subject.download_links).to eq [{ format: "EPUB", size: "19.5 KB", href: "/downloads/epub_id" },
                                          { format: "MOBI", size: "29.3 KB", href: "/downloads/mobi_id" },
                                          { format: "PDF",  size: "39.1 KB", href: "/downloads/pdfe_id" }]
  end
end
