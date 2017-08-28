# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

RSpec.describe EPubIndexService::Chapters do
  let(:epub_fileset) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
  let(:epub) { EPubIndexService::EPub.new(EPubsService.epub_path(epub_fileset.id)) }

  before do
    EPubsService.cache_epub(epub_fileset.id)
  end

  after do
    EPubsService.clear_cache
  end

  it "creates chapters" do
    chapters = described_class.create(epub)
    expect(chapters.first.href).to eq 'cover.xhtml'
    expect(chapters.last.href).to eq 'toc.xhtml'
  end
end
