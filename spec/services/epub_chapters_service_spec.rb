# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require 'zip'

RSpec.describe EpubChaptersService do
  # Splits an unpacked EPUB into per-ToC-entry EPUB files. The fixtures are
  # minimal, fake EPUBs at `spec/fixtures/epub_chapters/`. One of them
  # (9780000000001_continuation_cases.epub) has a ToC entry
  # ("Footnotes" -> fakebook1-0022.xhtml) whose spine continues into
  # fakebook1-0023.xhtml (which has no ToC entry of its own) before the
  # next top-level ToC entry (fakebook1-0024.xhtml). The other
  # (9780000000002_nested_toc_items.epub) exercises a ToC with nested
  # (multi-level) items.
  let(:sample_dir) { Rails.root.join('spec', 'fixtures', 'epub_chapters') }

  around do |example|
    Dir.mktmpdir do |tmp|
      @work_dir = tmp
      example.run
    end
  end

  def unpack(epub_path)
    dest = File.join(@work_dir, File.basename(epub_path, '.epub'))
    FileUtils.mkdir_p(dest)
    Zip::File.open(epub_path) do |zip_file|
      zip_file.each do |entry|
        out_path = File.join(dest, entry.name)
        FileUtils.mkdir_p(File.dirname(out_path))
        entry.extract(out_path) { true }
      end
    end
    dest
  end

  def open_chapter(chapter_epub_path)
    contents = {}
    Zip::File.open(chapter_epub_path) do |zip_file|
      zip_file.each do |entry|
        contents[entry.name] = entry.get_input_stream.read
      end
    end
    contents
  end

  # The spine hrefs actually written into a chapter epub's content.opf (which
  # can include files copied in beyond the ToC-planned spine, e.g. endnote and
  # extended-description files).
  def opf_spine_hrefs(contents, opf_key = 'OEBPS/content.opf')
    opf = Nokogiri::XML(contents[opf_key]).remove_namespaces!
    opf.xpath('//spine/itemref').map do |itemref|
      opf.at_xpath("//manifest/item[@id='#{itemref['idref']}']")['href']
    end
  end

  describe '.create_chapters' do
    context 'with a real-world EPUB' do
      let(:epub_root) { unpack(sample_dir.join('9780000000001_continuation_cases.epub').to_s) }
      let(:output_dir) { File.join(@work_dir, 'chapters') }

      it 'creates one .epub per ToC entry' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        files = Dir.glob(File.join(output_dir, '*.epub')).sort_by { |f| File.basename(f, '.epub').to_i }
        expect(files.length).to eq chapters.length
        expect(files.length).to be > 5
        expect(files.first).to end_with('/0.epub')
      end

      it 'produces valid EPUB archives with mimetype as the first (STORED) entry' do
        described_class.create_chapters(epub_root, output_dir)
        first_chapter = File.join(output_dir, '0.epub')
        Zip::File.open(first_chapter) do |zip|
          expect(zip.entries.first.name).to eq 'mimetype'
          expect(zip.entries.first.compression_method).to eq Zip::Entry::STORED
          expect(zip.read('mimetype')).to eq 'application/epub+zip'
        end
      end

      it 'includes the META-INF/container.xml and a content.opf pointing at it' do
        described_class.create_chapters(epub_root, output_dir)
        contents = open_chapter(File.join(output_dir, '0.epub'))
        expect(contents).to have_key('META-INF/container.xml')
        expect(contents['META-INF/container.xml']).to include('OEBPS/content.opf')
        expect(contents).to have_key('OEBPS/content.opf')
      end

      it 'bundles a ToC entry that spans multiple spine items together (continuation files)' do
        # In 9780000000001_continuation_cases.epub the ToC "Footnotes" entry
        # points at fakebook1-0022.xhtml, but the next ToC entry
        # "Bibliography" points at fakebook1-0024.xhtml. So -0022 AND -0023
        # (the continuation) should both be included in the Footnotes
        # chapter epub.
        chapters = described_class.create_chapters(epub_root, output_dir)
        footnotes_index = chapters.index { |c| c[:title].downcase.include?('footnote') }
        expect(footnotes_index).not_to be_nil
        expect(chapters[footnotes_index][:spine_hrefs])
          .to include('fakebook1-0022.xhtml', 'fakebook1-0023.xhtml')

        contents = open_chapter(File.join(output_dir, "#{footnotes_index}.epub"))
        expect(contents).to have_key('OEBPS/fakebook1-0022.xhtml')
        expect(contents).to have_key('OEBPS/fakebook1-0023.xhtml')
      end

      it 'copies referenced cross-file endnotes into the chapter (keeping the original filename) and trims the unreferenced ones' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        # "Chapter One" (-0009.xhtml) has noteref anchors pointing at
        # fakebook1-0022.xhtml#fn1..fn3 (the Footnotes file, a different chapter).
        ch_idx = chapters.index { |c| c[:spine_hrefs].include?('fakebook1-0009.xhtml') }
        expect(ch_idx).not_to be_nil
        contents = open_chapter(File.join(output_dir, "#{ch_idx}.epub"))

        # The noteref hrefs are left untouched: they still point at the (now
        # copied-in) endnotes file, which keeps its original filename.
        body = contents['OEBPS/fakebook1-0009.xhtml']
        expect(body).to include('href="fakebook1-0022.xhtml#fn1"')
        expect(body).to include('epub:type="noteref"')

        # The endnotes file itself is copied into the chapter epub, and its
        # spine entry is added to the content.opf.
        expect(contents).to have_key('OEBPS/fakebook1-0022.xhtml')
        expect(opf_spine_hrefs(contents)).to include('fakebook1-0022.xhtml')

        # Only the referenced notes (fn1, fn2, fn3) are copied; the unreferenced
        # notes (fn4, fn5) are trimmed away.
        notes = contents['OEBPS/fakebook1-0022.xhtml']
        expect(notes).to include('id="fn1"', 'id="fn2"', 'id="fn3"')
        expect(notes).not_to include('id="fn4"')
        expect(notes).not_to include('id="fn5"')
        # The copied notes keep their proper EPUB markup and back-links.
        expect(notes).to include('epub:type="endnote"')
        expect(notes).to include('href="fakebook1-0009.xhtml#fn1r"')
      end

      it 'copies the whole target file of an "extended description" link into the chapter' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        # "Chapter Two" (-0010.xhtml) has a <p class="image-right_back"> link to
        # fakebook1-ext-0001.xhtml (a tail-of-spine, non-ToC file).
        ch_idx = chapters.index { |c| c[:spine_hrefs].include?('fakebook1-0010.xhtml') }
        expect(ch_idx).not_to be_nil
        contents = open_chapter(File.join(output_dir, "#{ch_idx}.epub"))

        # The forward link is left untouched (the file is now present).
        body = contents['OEBPS/fakebook1-0010.xhtml']
        expect(body).to include('href="fakebook1-ext-0001.xhtml#ed1"')

        # The extended-description file is copied verbatim and added to the spine.
        expect(contents).to have_key('OEBPS/fakebook1-ext-0001.xhtml')
        expect(opf_spine_hrefs(contents)).to include('fakebook1-ext-0001.xhtml')
        ext = contents['OEBPS/fakebook1-ext-0001.xhtml']
        expect(ext).to include('Extended Description for Figure 1')
        expect(ext).to include('A long textual description')
        # Its image resource is bundled too.
        expect(contents.keys).to include('OEBPS/images/cover.jpg')
      end

      it 'still rewrites other cross-chapter links as in-chapter placeholder endnotes' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        # The Footnotes chapter (-0022.xhtml) contains doc-backlink anchors that
        # point back at chapters (-0009/-0011) not present in its own epub. Those
        # are neither noterefs nor extended-description links, so they fall
        # through to the placeholder-endnote behavior.
        ch_idx = chapters.index { |c| c[:spine_hrefs].first == 'fakebook1-0022.xhtml' }
        expect(ch_idx).not_to be_nil
        contents = open_chapter(File.join(output_dir, "#{ch_idx}.epub"))
        last_href = chapters[ch_idx][:spine_hrefs].last
        last_body = contents["OEBPS/#{last_href}"]
        expect(last_body).to include('doc-endnotes')
        expect(last_body).to include('id="epub-chapter-endnote-1"')
      end

      it 'preserves external (http) and fragment-only links untouched' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        ch_idx = chapters.index { |c| c[:spine_hrefs].include?('fakebook1-0009.xhtml') }
        body = open_chapter(File.join(output_dir, "#{ch_idx}.epub"))['OEBPS/fakebook1-0009.xhtml']
        # The original file uses anchored fnref links of the form `<file>#anchor`
        # so any pure `#anchor` href in the output should be one of our endnotes.
        Nokogiri::XML(body).remove_namespaces!.css('a[href]').each do |a|
          href = a['href']
          if href.start_with?('#')
            expect(href).to start_with('#epub-chapter-endnote-')
          end
        end
      end

      it 'copies referenced images into the chapter epub' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        # The cover xhtml uses the cover image
        cover_idx = chapters.index { |c| c[:spine_hrefs].include?('fakebook1-0001.xhtml') }
        expect(cover_idx).not_to be_nil
        contents = open_chapter(File.join(output_dir, "#{cover_idx}.epub"))
        # any jpg/jpeg image is fine
        expect(contents.keys.any? { |k| k.match?(/\.(jpe?g|png|gif|svg)\z/i) }).to be true
      end

      it 'writes a content.opf whose manifest matches the included files and whose spine matches the chapter spine_hrefs' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        contents = open_chapter(File.join(output_dir, '0.epub'))
        opf = Nokogiri::XML(contents['OEBPS/content.opf']).remove_namespaces!
        spine_hrefs = opf.xpath('//spine/itemref').map do |itemref|
          opf.at_xpath("//manifest/item[@id='#{itemref['idref']}']")['href']
        end
        expect(spine_hrefs).to eq chapters[0][:spine_hrefs]

        opf.xpath('//manifest/item').each do |item|
          # nav file is included even though we don't ship original chapters of
          # the book's resources; ensure each manifest entry exists in the zip
          href = item['href']
          path = "OEBPS/#{href}"
          expect(contents).to have_key(path), "expected manifest item #{href} to be present in archive"
        end
      end
    end

    context 'with a second real-world EPUB (nested ToC)' do
      # 9780000000002_nested_toc_items.epub has a ToC with three levels of
      # nesting (Section -> Chapter -> Subsection). Every one of the 20 spine
      # files is directly referenced by its own <li>/<a> entry in the ToC,
      # so the new "one chapter EPUB per ToC entry" logic must produce 20
      # single-spine-file chapter EPUBs, in ToC document order.
      let(:epub_root) { unpack(sample_dir.join('9780000000002_nested_toc_items.epub').to_s) }
      let(:output_dir) { File.join(@work_dir, 'chapters2') }

      let(:expected_titles) do
        [
          'Cover', 'Title Page', 'Contents', 'Foreword', 'Introduction',
          'Section 1', 'Chapter 1.1', 'Subsection 1.1.1', 'Subsection 1.1.2',
          'Chapter 1.2', 'Subsection 1.2.1', 'Subsection 1.2.2',
          'Section 2', 'Chapter 2.1', 'Subsection 2.1.1', 'Subsection 2.1.2',
          'Chapter 2.2', 'Subsection 2.2.1', 'Subsection 2.2.2',
          'Afterword'
        ]
      end

      let(:expected_spine_hrefs) do
        (1..20).map { |i| [format('fakebook2-%04d.xhtml', i)] }
      end

      # For each ToC entry (by title, in document order), the spine files that
      # its chapter EPUB is expected to contain. Parent entries include all of
      # their nested descendants' spine files, so e.g. "Section 1" holds
      # fakebook2-0006 through fakebook2-0012 (through the last subsection
      # before "Section 2"), while "Chapter 1.1" holds -0007..-0009, etc.
      let(:expected_hierarchical_spine_hrefs) do
        fmt = ->(range) { range.map { |i| format('fakebook2-%04d.xhtml', i) } }
        [
          fmt.call(1..1),   # Cover
          fmt.call(2..2),   # Title Page
          fmt.call(3..3),   # Contents
          fmt.call(4..4),   # Foreword
          fmt.call(5..5),   # Introduction
          fmt.call(6..12),  # Section 1 (contains Chapters 1.1-1.2 and their subsections)
          fmt.call(7..9),   # Chapter 1.1 (contains Subsections 1.1.1-1.1.2)
          fmt.call(8..8),   # Subsection 1.1.1
          fmt.call(9..9),   # Subsection 1.1.2
          fmt.call(10..12), # Chapter 1.2 (contains Subsections 1.2.1-1.2.2)
          fmt.call(11..11), # Subsection 1.2.1
          fmt.call(12..12), # Subsection 1.2.2
          fmt.call(13..19), # Section 2
          fmt.call(14..16), # Chapter 2.1
          fmt.call(15..15), # Subsection 2.1.1
          fmt.call(16..16), # Subsection 2.1.2
          fmt.call(17..19), # Chapter 2.2
          fmt.call(18..18), # Subsection 2.2.1
          fmt.call(19..19), # Subsection 2.2.2
          fmt.call(20..20)  # Afterword
        ]
      end

      it 'creates one chapter EPUB per ToC <li> (including nested entries)' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        files = Dir.glob(File.join(output_dir, '*.epub'))
        expect(files.length).to eq chapters.length
        expect(chapters.length).to eq 20
      end

      it 'preserves ToC document order in chapter titles and output file indexes' do
        chapters = described_class.create_chapters(epub_root, output_dir)
        expect(chapters.pluck(:title)).to eq expected_titles
        # Parent ToC entries encompass all of their nested descendants' spine files.
        expect(chapters.pluck(:spine_hrefs)).to eq expected_hierarchical_spine_hrefs
        # And the on-disk files are named <index>.epub for 0..19
        (0..19).each do |i|
          expect(File.exist?(File.join(output_dir, "#{i}.epub"))).to be(true), "expected #{i}.epub to exist"
        end
      end

      it 'nests every descendant spine file inside each parent ToC entry\'s chapter EPUB' do
        described_class.create_chapters(epub_root, output_dir)
        expected_hierarchical_spine_hrefs.each_with_index do |hrefs, i|
          contents = open_chapter(File.join(output_dir, "#{i}.epub"))
          xhtml_keys = contents.keys.select { |k| k.end_with?('.xhtml') && k != 'OEBPS/toc.xhtml' }
          expect(xhtml_keys.sort).to eq(hrefs.map { |h| "OEBPS/#{h}" }.sort)
        end
      end

      it 'writes a content.opf per chapter whose spine matches the (possibly-nested) ToC entry' do
        described_class.create_chapters(epub_root, output_dir)
        expected_hierarchical_spine_hrefs.each_with_index do |hrefs, i|
          contents = open_chapter(File.join(output_dir, "#{i}.epub"))
          opf = Nokogiri::XML(contents['OEBPS/content.opf']).remove_namespaces!
          spine_hrefs = opf.xpath('//spine/itemref').map do |itemref|
            opf.at_xpath("//manifest/item[@id='#{itemref['idref']}']")['href']
          end
          expect(spine_hrefs).to eq(hrefs)
          # Title in the per-chapter opf metadata should include the ToC entry title
          expect(opf.at_xpath('//metadata/title').text).to include(expected_titles[i])
        end
      end

      it 'writes a per-chapter nav.xhtml whose ToC nests links to every included descendant' do
        described_class.create_chapters(epub_root, output_dir)

        # "Section 1" (index 5): parent li has nested <ol> for Chapters 1.1 & 1.2,
        # each of which has its own nested <ol> for its two subsections.
        contents = open_chapter(File.join(output_dir, '5.epub'))
        nav = Nokogiri::XML(contents['OEBPS/toc.xhtml']).remove_namespaces!
        top_ol = nav.at_xpath("//nav[@id='toc']/ol")
        expect(top_ol).not_to be_nil

        top_lis = top_ol.xpath('./li')
        expect(top_lis.length).to eq 1
        expect(top_lis.first.at_xpath('./a').text).to eq 'Section 1'

        chapter_lis = top_lis.first.xpath('./ol/li')
        expect(chapter_lis.map { |li| li.at_xpath('./a').text }).to eq ['Chapter 1.1', 'Chapter 1.2']

        chapter_1_1_subs = chapter_lis[0].xpath('./ol/li')
        expect(chapter_1_1_subs.map { |li| li.at_xpath('./a').text })
          .to eq ['Subsection 1.1.1', 'Subsection 1.1.2']

        chapter_1_2_subs = chapter_lis[1].xpath('./ol/li')
        expect(chapter_1_2_subs.map { |li| li.at_xpath('./a').text })
          .to eq ['Subsection 1.2.1', 'Subsection 1.2.2']

        # Nested anchors resolve to files that are actually in the chapter epub
        %w[Chapter\ 1.1 Chapter\ 1.2 Subsection\ 1.1.1 Subsection\ 1.1.2
           Subsection\ 1.2.1 Subsection\ 1.2.2].each do |title|
          a = top_ol.xpath(".//a[normalize-space(text())='#{title}']").first
          expect(a).not_to be_nil, "expected nav to contain link for #{title}"
          expect(contents).to have_key("OEBPS/#{a['href']}"), "expected nav link target #{a['href']} to be in the chapter epub"
        end

        # A leaf entry ("Subsection 1.1.1", index 7) should have no nested <ol>.
        leaf_nav = Nokogiri::XML(open_chapter(File.join(output_dir, '7.epub'))['OEBPS/toc.xhtml']).remove_namespaces!
        leaf_top = leaf_nav.at_xpath("//nav[@id='toc']/ol")
        expect(leaf_top.xpath('./li').length).to eq 1
        expect(leaf_top.at_xpath('./li/ol')).to be_nil
        expect(leaf_top.at_xpath('./li/a').text).to eq 'Subsection 1.1.1'
      end
    end
  end
end
