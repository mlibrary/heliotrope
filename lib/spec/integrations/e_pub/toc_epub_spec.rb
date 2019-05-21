# frozen_string_literal: true

RSpec.describe "TOC EPub" do
  subject(:publication) { EPub::Publication.from_directory(File.join(Dir.pwd, 'spec', 'fixtures', epub_dir)) }

  context "01 with anchors" do
    subject(:intervals) { publication.rendition.intervals }

    let(:epub_dir) { 'toc_epub_01' }

    it { expect(intervals[0].cfi).to eq('/EPUB/xhtml/Chapter01.xhtml%231') }
  end

  context "02 without anchors" do
    subject(:intervals) { publication.rendition.intervals }

    let(:epub_dir) { 'toc_epub_02' }

    it { expect(intervals[0].cfi).to eq('/6/2[Chapter01]!/4/1:0') }
  end
end
