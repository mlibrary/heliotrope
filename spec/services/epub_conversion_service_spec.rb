# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require 'nokogiri'

RSpec.describe EpubConversionService do
  # Fixtures are minimal *unpacked* EPUBs at
  # spec/fixtures/epub_conversion/. `epub2_minimal` is an EPUB 2.0.1
  # publication (version="2.0", NCX-only navigation, XHTML 1.1 DOCTYPEs,
  # opf:scheme/opf:role/opf:file-as metadata attributes, a Content-Type
  # http-equiv meta). `epub3_minimal` is already EPUB 3.
  let(:fixtures) { Rails.root.join('spec', 'fixtures', 'epub_conversion') }

  around do |example|
    Dir.mktmpdir do |tmp|
      @work_dir = tmp
      example.run
    end
  end

  # Copy an unpacked fixture into the tmp work dir so the in-place migration
  # doesn't mutate the checked-in fixture.
  def copy_fixture(name)
    dest = File.join(@work_dir, name)
    FileUtils.cp_r(fixtures.join(name).to_s, dest)
    dest
  end

  def opf(root, opf_rel = 'OEBPS/content.opf')
    Nokogiri::XML(File.read(File.join(root, opf_rel)))
  end

  describe '.epub2?' do
    it 'is true for an EPUB 2.x publication' do
      expect(described_class.epub2?(copy_fixture('epub2_minimal'))).to be true
    end

    it 'is false for an EPUB 3 publication' do
      expect(described_class.epub2?(copy_fixture('epub3_minimal'))).to be false
    end
  end

  describe '.migrate' do
    context 'with an EPUB 2.x publication' do
      let(:root) { copy_fixture('epub2_minimal') }

      before { described_class.migrate(root) }

      it 'returns true and bumps the package version to 3.0' do
        package = opf(root).at_xpath('//*[local-name()="package"]')
        expect(package['version']).to eq '3.0'
      end

      it 'adds exactly one dcterms:modified meta' do
        modified = opf(root).xpath('//*[local-name()="meta"][@property="dcterms:modified"]')
        expect(modified.length).to eq 1
        expect(modified.first.text).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
      end

      it 'strips EPUB2-only opf: metadata attributes rejected by EPUB3' do
        opf_xml = File.read(File.join(root, 'OEBPS', 'content.opf'))
        expect(opf_xml).not_to include('opf:scheme')
        expect(opf_xml).not_to include('opf:role')
        expect(opf_xml).not_to include('opf:file-as')
      end

      it 'registers a navigation document in the manifest' do
        nav_item = opf(root).xpath('//*[local-name()="item"]').find do |item|
          item['properties'].to_s.split(/\s+/).include?('nav')
        end
        expect(nav_item).not_to be_nil
        expect(File.exist?(File.join(root, 'OEBPS', nav_item['href']))).to be true
      end

      it 'builds the nav document from the NCX, preserving nesting and hrefs' do
        nav_item = opf(root).xpath('//*[local-name()="item"]').find { |i| i['properties'].to_s.include?('nav') }
        nav = Nokogiri::XML(File.read(File.join(root, 'OEBPS', nav_item['href'])))
        links = nav.xpath('//*[local-name()="a"]')
        expect(links.map(&:text)).to include('Chapter One', 'A Subsection', 'Chapter & Two')
        expect(links.map { |a| a['href'] }).to include('text/chapter1.xhtml', 'text/chapter2.xhtml')
        # nested navPoint becomes a nested <ol>
        expect(nav.xpath('//*[local-name()="ol"]//*[local-name()="ol"]')).not_to be_empty
      end

      it 'replaces irregular DOCTYPEs with <!DOCTYPE html>' do
        chapter = File.read(File.join(root, 'OEBPS', 'text', 'chapter1.xhtml'))
        expect(chapter).to include('<!DOCTYPE html>')
        expect(chapter).not_to include('XHTML 1.1')
      end

      it 'normalizes the Content-Type http-equiv meta to text/html' do
        chapter = File.read(File.join(root, 'OEBPS', 'text', 'chapter1.xhtml'))
        expect(chapter).to include('content="text/html; charset=utf-8"')
        expect(chapter).not_to include('application/xhtml+xml; charset=utf-8')
      end

      it 'injects an underline style for in-text links (link-in-text-block)' do
        chapter = File.read(File.join(root, 'OEBPS', 'text', 'chapter1.xhtml'))
        expect(chapter).to include('a[href] { text-decoration: underline; }')
      end
    end

    it 'returns true for EPUB 2.x and false for EPUB 3.x' do
      expect(described_class.migrate(copy_fixture('epub2_minimal'))).to be true
      expect(described_class.migrate(copy_fixture('epub3_minimal'))).to be false
    end

    it 'leaves an EPUB 3 publication untouched' do
      root = copy_fixture('epub3_minimal')
      before_xml = File.read(File.join(root, 'OEBPS', 'content.opf'))
      described_class.migrate(root)
      expect(File.read(File.join(root, 'OEBPS', 'content.opf'))).to eq before_xml
    end

    it 'is idempotent: a second run is a no-op' do
      root = copy_fixture('epub2_minimal')
      expect(described_class.migrate(root)).to be true
      after_first = File.read(File.join(root, 'OEBPS', 'text', 'chapter1.xhtml'))
      expect(described_class.migrate(root)).to be false
      expect(File.read(File.join(root, 'OEBPS', 'text', 'chapter1.xhtml'))).to eq after_first
    end
  end
end
