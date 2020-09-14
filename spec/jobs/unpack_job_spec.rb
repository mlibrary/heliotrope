# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpackJob, type: :job do
  include ActiveJob::TestHelper

  describe "perform" do
    context "with a missing original_file" do
      let(:no_file_file_set) { create(:file_set) }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      it 'raises Resque::Job::DontPerform, which is discarded, and does not create a derivatives directory' do
        expect(described_class.perform_now(no_file_file_set.id, 'epub').class).to eq(Resque::Job::DontPerform)
        expect(Dir.exist?(File.dirname(UnpackService.root_path_from_noid(no_file_file_set.id, 'epub')))).to be false
      end
    end

    context "with an epub" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      it "unzips the epub, caches the ToC and creates the database" do
        described_class.perform_now(epub.id, 'epub')
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: epub.id).toc).length).to eq 3
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: epub.id).toc)[0]["title"]).to eq "Damage report!"
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: epub.id).toc)[0]["level"]).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: epub.id).toc)[0]["cfi"]).to eq "/6/2[Chapter01]!/4/1:0"
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: epub.id).toc)[0]["downloadable?"]).to eq false
        expect(File.exist?(File.join(root_path, epub.id + '.db'))).to be true
      end
    end

    context "with a webgl" do
      let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
      let(:root_path) { UnpackService.root_path_from_noid(webgl.id, 'webgl') }

      it "unzips the webgl" do
        described_class.perform_now(webgl.id, 'webgl')
        expect(File.exist?(File.join(root_path, "Build", "UnityLoader.js"))).to be true
      end
    end

    context "with a pdf_ebook" do
      let(:pdf_ebook) { create(:file_set, content: File.open(File.join(fixture_path, 'lorum_ipsum_toc.pdf'))) }
      let(:root_path) { UnpackService.root_path_from_noid(pdf_ebook.id, 'pdf_ebook') }
      let(:chapters_dir) { UnpackService.root_path_from_noid(pdf_ebook.id, 'pdf_ebook_chapters') }

      it "makes the pdf_ebook, caches the ToC and makes the chapter files derivatives" do
        described_class.perform_now(pdf_ebook.id, 'pdf_ebook')
        expect(File.exist?("#{root_path}.pdf")).to be true
        expect(Dir.exist?(chapters_dir)).to be true
        expect(Dir.glob(File.join(chapters_dir, '**', '*')).select { |file| File.file?(file) }.count).to eq 6
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc).length).to eq 6
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]["title"]).to eq "The standard Lorem Ipsum passage, used since the 1500s"
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]["level"]).to eq 1
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]["cfi"]).to eq "page=3"
        # As far as EbooksTableOfContents is concerned, if the chapters exist, they are downloadable? = true
        # The application itself (see views/monograph_catalog/_index_epub_toc.html.erb) will use policy/checkpoint/auth
        # in combination with this to show or hide download links
        expect(JSON.parse(EbookTableOfContentsCache.find_by(noid: pdf_ebook.id).toc)[0]["downloadable?"]).to eq true
      end
    end

    context "with an epub and pre-existing webgl" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let!(:fre) { create(:featured_representative, work_id: 'mono_id', file_set_id: epub.id, kind: 'epub') }
      let!(:frw) { create(:featured_representative, work_id: 'mono_id', file_set_id: '123456789', kind: 'webgl') }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      after { FeaturedRepresentative.destroy_all }

      it "creates the epub-webgl map" do
        described_class.perform_now(epub.id, 'epub')
        expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be true
      end
    end

    context "with a pre-existing epub" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }

      before do
        # we need the epub already unpacked in order to store the epub-webgl map file
        described_class.perform_now(epub.id, 'epub')
      end

      after { FeaturedRepresentative.destroy_all }

      context "adding a webgl" do
        let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
        let!(:fre) { create(:featured_representative, work_id: 'mono_id', file_set_id: epub.id, kind: 'epub') }
        let!(:frw) { create(:featured_representative, work_id: 'mono_id', file_set_id: webgl.id, kind: 'webgl') }
        # The root_path of the epub, not the webgl is used to test
        let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

        it "creates the epub-webgl map" do
          expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be false
          described_class.perform_now(webgl.id, 'webgl')
          expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be true
        end
      end
    end

    context "with a map" do
      let(:map) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-map.zip'))) }
      let(:root_path) { UnpackService.root_path_from_noid(map.id, 'interactive_map') }

      after { FileUtils.rm_rf(root_path) }

      it "unzips the map" do
        described_class.perform_now(map.id, 'interactive_map')
        expect(File.exist?(File.join(root_path, 'index.html'))).to be true
      end
    end
  end
end
