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
      let(:sm_epub) { File.join(root_path, epub.id + ".sm.epub") }
      let(:sm_dir) { File.join(root_path, epub.id + ".sm") }
      before do
        # The UnpackJob actually calls the SmallEpubJob
        # So delete what the SmallEpubJob created then run it alone
        UnpackJob.perform_now(epub.id, 'epub')
        FileUtils.rm sm_epub
        FileUtils.rm_rf sm_dir
      end

      it "creates the small epub" do
        expect(File.exist?(sm_epub)).to be false
        expect(Dir.exist?(sm_dir)).to be false

        MinimalEpubJob.perform_now(root_path)

        expect(File.exist?(sm_epub)).to be true
        expect(Dir.exist?(sm_dir)).to be true

        # no sqlite file
        expect(File.exist?(File.join(sm_dir, epub.id + ".db"))).to be false
        # no png page images
        expect(Dir.glob(sm_dir + "OEBPS/images/*.png").count).to be 0
        # rewrite images paths in the spine
        expect(IO.readlines(File.join(sm_dir, "OEBPS/content_fixed_scan.opf")).map { |l| l.match("epubs/#{epub.id}/OEBPS/images/00000003.png") }.compact.count).to eq 1
        # rewrite images paths in the xhtml
        expect(IO.readlines(File.join(sm_dir, "OEBPS/xhtml/00000001_fixed_scan.xhtml")).map { |l| l.match("epubs/#{epub.id}/OEBPS/images/00000001.png") }.compact.count).to eq 1
      end
    end
  end
end
