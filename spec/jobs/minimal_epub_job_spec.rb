# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MinimalEpubJob, type: :job do
  describe "perform" do
    context "if the epub is not first unpacked" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub_muilti_rendition.epub'))) }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }
      let(:sm_epub) { File.join(root_path, epub.id + ".sm.epub") }

      it "does nothing" do
        MinimalEpubJob.perform_now(root_path)
        expect(File.exist?(sm_epub)).to be false
      end
    end

    context "if the epub has been unpacked" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub_muilti_rendition.epub'))) }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }
      let(:sm_epub) { File.join(root_path, epub.id + '.sm.epub') }
      let(:sm_dir) { File.join(root_path, epub.id + '.sm') }
      let(:sm_dir_testing) { sm_dir + '.testing' }

      before do
        # The UnpackJob actually calls the MinimalEpubJob
        # So to test, delete what the MinimalEpubJob created then run it alone
        UnpackJob.perform_now(epub.id, 'epub')
        FileUtils.rm sm_epub
      end

      it "creates the small epub" do
        expect(File.exist?(sm_epub)).to be false
        expect(Dir.exist?(sm_dir)).to be false

        # Part of MinimalEpubJob is deleting the .sm working directory when done.
        # For testing however it's better if we have those files to examine.
        allow(FileUtils).to receive(:remove_entry_secure).with(sm_dir).and_return(true)
        MinimalEpubJob.perform_now(root_path)
        # But we'll move them so we can test that the deletion of .sm happened too
        FileUtils.move sm_dir, sm_dir_testing

        expect(File.exist?(sm_epub)).to be true
        # The .sm working directory has been deleted
        expect(Dir.exist?(sm_dir)).to be false

        # no sqlite file
        expect(File.exist?(File.join(sm_dir_testing, epub.id + ".db"))).to be false
        # no png page images
        expect(Dir.glob(sm_dir_testing + "OEBPS/images/*.png").count).to be 0
        # rewrite images paths in the spine
        expect(IO.readlines(File.join(sm_dir_testing, "OEBPS/content_fixed_scan.opf")).map { |l| l.match("epubs/#{epub.id}/OEBPS/images/00000003.png") }.compact.count).to eq 1
        # rewrite images paths in the xhtml
        expect(IO.readlines(File.join(sm_dir_testing, "OEBPS/xhtml/00000001_fixed_scan.xhtml")).map { |l| l.match("epubs/#{epub.id}/OEBPS/images/00000001.png") }.compact.count).to eq 1
      end
    end
  end

  describe "#update_cover" do
    let(:cover) { Rails.root.join('tmp', 'fake-cover.xhtml') }
    let(:epub) { double("epub", id: '999999999') }

    before do
      File.open(cover, 'w') do |f|
        f.puts '<img src="../images/9780472125616_cover.jpg"/>'
      end
    end

    after { FileUtils.rm cover }

    it "changes the cover's path" do
      described_class.new.update_cover(cover, epub)
      expect(IO.readlines(File.open(cover))[0].chomp).to eq '<img src="/epubs/999999999/OEBPS/images/9780472125616_cover.jpg"/>'
    end
  end
end
