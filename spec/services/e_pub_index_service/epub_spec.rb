# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

RSpec.describe EPubIndexService::EPub do
  before(:all) do # rubocop:disable BeforeAfterAll
    @epub = create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub')))
    EPubsService.cache_epub(@epub.id)
  end

  after(:all) do # rubocop:disable BeforeAfterAll
    ::EPubsService.clear_cache
  end

  context "has the correct attributes" do
    subject { described_class.new(EPubsService.epub_path(@epub.id)) }

    it "container" do
      expect(subject.container.xpath("//container/rootfiles/rootfile")).to_not be nil
    end

    it "content file" do
      expect(subject.content_file).to eq "OPS/package.opf"
    end

    it "content dir" do
      expect(subject.content_dir).to eq "OPS"
    end

    it "content" do
      expect(subject.content.xpath("//spine")[0].name).to eq 'spine'
    end
  end
end
