# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EBookDownloadPresenter do
  subject { described_class.new(mono, current_ability, current_actor) }

  let(:user) { create(:user) }
  let(:current_ability) { Ability.new(user) }
  let(:current_actor) { user }

  let(:press) { create(:press) }
  let(:mono) { Hyrax::MonographPresenter.new(SolrDocument.new(id: 'validnoid', visibility_ssi: 'open', has_model_ssim: ['Monograph'], press_name_ssim: [press.subdomain]), current_ability) }
  let(:epub_doc) { SolrDocument.new(id: '111111111', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 20_000, allow_download_ssim: 'yes') }
  let(:mobi_doc) { SolrDocument.new(id: '222222222', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 30_000, allow_download_ssim: 'yes') }
  let(:pdf_doc) { SolrDocument.new(id: '333333333', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 40_000, allow_download_ssim: 'yes') }
  let(:audiobook_doc) { SolrDocument.new(id: '444444444', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 50_000, allow_download_ssim: 'yes') }

  before do
    allow(Sighrax).to receive(:from_noid).with('validnoid').and_return(Sighrax.from_presenter(mono))
    create(:featured_representative, file_set_id: '111111111', work_id: 'validnoid', kind: 'epub')
    create(:featured_representative, file_set_id: '222222222', work_id: 'validnoid', kind: 'mobi')
    create(:featured_representative, file_set_id: '333333333', work_id: 'validnoid', kind: 'pdf_ebook')
    create(:featured_representative, file_set_id: '444444444', work_id: 'validnoid', kind: 'audiobook')
    ActiveFedora::SolrService.add([epub_doc.to_h, mobi_doc.to_h, pdf_doc.to_h, audiobook_doc.to_h])
    ActiveFedora::SolrService.commit
  end

  context "formats" do
    it "has the right ebook format" do
      expect(subject.epub.ebook_format).to eq "EPUB"
      expect(subject.mobi.ebook_format).to eq "MOBI"
      expect(subject.pdf_ebook.ebook_format).to eq "PDF"
      expect(subject.audiobook.ebook_format).to eq "AUDIO BOOK MP3" # wording requested by Fulcrum Steering (file may be an mp3 or a zip archive containing several mp3 files)
    end
  end

  context "file sizes" do
    it "has file sizes" do
      expect(subject.epub.file_size).to eq 20_000
      expect(subject.mobi.file_size).to eq 30_000
      expect(subject.pdf_ebook.file_size).to eq 40_000
      expect(subject.audiobook.file_size).to eq 50_000
    end
  end

  describe "#downloadable?" do
    it "is downloadable" do
      expect(subject.downloadable?(subject.epub)).to be true
      expect(subject.downloadable?(subject.mobi)).to be true
      expect(subject.downloadable?(subject.pdf_ebook)).to be true
    end
  end

  context "csb_download_links" do
    let(:plain_links) { [{ format: "EPUB", size: "19.5 KB", href: "/ebooks/111111111/download" },
                         { format: "MOBI", size: "29.3 KB", href: "/ebooks/222222222/download" },
                         { format: "PDF",  size: "39.1 KB", href: "/ebooks/333333333/download" },
                         { format: "AUDIO BOOK MP3",  size: "48.8 KB", href: "/ebooks/444444444/download" }] }

    let(:pdf_warning_links) { [{ format: "EPUB", size: "19.5 KB", href: "/ebooks/111111111/download" },
                               { format: "MOBI", size: "29.3 KB", href: "/ebooks/222222222/download" },
                               { format: "PDF --- Editors, please note this is *not* the repository PDF --- It has been compressed and may be watermarked --- Do *not* use this file for editing! ---",
                                 size: "39.1 KB",
                                 href: "/ebooks/333333333/download" },
                               { format: "AUDIO BOOK MP3",  size: "48.8 KB", href: "/ebooks/444444444/download" }] }

    it 'produces an array of hashes with the download links as required by CSB' do
      expect(subject.csb_download_links).to eq plain_links
    end

    describe 'adding a warning to the PDF format/label for editors' do
      context 'Anonymous user' do
        let(:user) { Anonymous.new({}) }
        let(:current_ability) { nil }

        it 'does not add a warning to the PDF format/label' do
          expect(subject.csb_download_links).to eq plain_links
        end
      end

      context 'press analyst' do
        let(:user) { create(:press_analyst, press: press) }

        it 'adds a warning to the PDF format/label' do
          expect(subject.csb_download_links).to eq pdf_warning_links
        end
      end

      context 'press editor' do
        let(:user) { create(:press_editor, press: press) }

        it 'adds a warning to the PDF format/label' do
          expect(subject.csb_download_links).to eq pdf_warning_links
        end
      end

      context 'press admin' do
        let(:user) { create(:press_admin, press: press) }

        it 'adds a warning to the PDF format/label' do
          expect(subject.csb_download_links).to eq pdf_warning_links
        end
      end

      context 'platform admin' do
        let(:user) { create(:platform_admin) }

        it 'adds a warning to the PDF format/label' do
          expect(subject.csb_download_links).to eq pdf_warning_links
        end
      end
    end
  end

  describe "#downloadable_ebooks?" do
    context "with downloadable ebooks" do
      it "returns true" do
        expect(subject.downloadable_ebooks?).to be true
      end
    end

    context "with a downloadable ebook" do
      let(:epub_doc) { SolrDocument.new(id: '111111111', visibility_ssi: 'restricted', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 20_000, allow_download_ssim: 'no') }
      let(:mobi_doc) { SolrDocument.new(id: '222222222', visibility_ssi: 'restricted', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 30_000, allow_download_ssim: 'no') }
      let(:pdf_doc) { SolrDocument.new(id: '333333333', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 40_000, allow_download_ssim: 'yes') }
      let(:audiobook_doc) { SolrDocument.new(id: '444444444', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 40_000, allow_download_ssim: 'no') }

      it "returns true" do
        expect(subject.downloadable_ebooks?).to be true
      end
    end

    context "with no downloadable ebooks" do
      let(:epub_doc) { SolrDocument.new(id: '111111111', visibility_ssi: 'restricted', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 20_000, allow_download_ssim: 'no') }
      let(:mobi_doc) { SolrDocument.new(id: '222222222', visibility_ssi: 'restricted', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 30_000, allow_download_ssim: 'no') }
      let(:pdf_doc) { SolrDocument.new(id: '333333333', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 40_000, allow_download_ssim: 'no') }
      let(:audiobook_doc) { SolrDocument.new(id: '444444444', visibility_ssi: 'open', monograph_id_ssim: 'validnoid', has_model_ssim: ['FileSet'], file_size_lts: 40_000, allow_download_ssim: 'no') }

      it "returns false" do
        expect(subject.downloadable_ebooks?).to be false
      end
    end
  end
end
