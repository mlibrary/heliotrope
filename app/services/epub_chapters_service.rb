# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'set'
require 'securerandom'
require 'tmpdir'
require 'zip'

# Splits an unpacked EPUB into one downloadable EPUB per top-level Table of
# Contents entry. Each output EPUB is named `<index>.epub` (where index matches
# the order/index of top-level ToC entries) and is written to `output_dir`.
#
# Behavior notes:
# - The minimum downloadable unit is a single spine item. A single top-level
#   ToC entry can encompass several "continuation" spine items (those that
#   appear in the spine between this ToC entry's target and the next top-level
#   ToC entry's target). All such spine items are included in the chapter EPUB.
# - Hyperlinks inside the chapter to other files in the same chapter, and
#   fragment-only or external (mailto:, http(s)://, etc.) links, are kept as-is.
# - Two kinds of cross-file links have their *destination content* copied into
#   the chapter EPUB so the reader can still follow them:
#     1. Endnote references (`<a epub:type="noteref">`) that point at note
#        definitions (`epub:type="endnote"`/`"footnote"`/`"rearnote"`) living
#        in another spine file. Only the note definitions actually referenced
#        by this chapter are copied, into a file that keeps the original
#        filename (so the existing hrefs keep resolving).
#     2. "Extended description" links — an `<a>` inside a paragraph carrying the
#        `image-right_back` class (the only reliable marker these vendors give
#        us). The whole target file is copied in verbatim.
# - Any *other* hyperlink to a file outside this chapter is rewritten as an
#   in-chapter endnote that states the ToC entry the link originally targeted.
#   This preserves the link's reading context while remaining accessible.
module EpubChaptersService
  module_function

  # Build chapter EPUBs from the unpacked EPUB at `epub_root_path` into
  # `output_dir`. Returns an Array of Hashes describing the created chapters.
  def create_chapters(epub_root_path, output_dir)
    Builder.new(epub_root_path, output_dir).build
  end

  class Builder # rubocop:disable Metrics/ClassLength
    OPF_NS  = 'http://www.idpf.org/2007/opf'
    DC_NS   = 'http://purl.org/dc/elements/1.1/'
    XHTML_NS = 'http://www.w3.org/1999/xhtml'
    EPUB_NS = 'http://www.idpf.org/2007/ops'

    # epub:type values that mark a *note definition* (the thing a noteref points
    # at). Deliberately excludes "noteref" (the reference itself).
    NOTE_DEFINITION_TYPES = %w[endnote footnote rearnote].freeze

    # Paragraph class(es) that wrap an "extended description" link. This is the
    # only reliable marker the sampled vendors give us to detect these links.
    EXTENDED_DESCRIPTION_CLASSES = %w[image-right_back].freeze

    # Per-chapter accumulator threaded through the link-rewriting pass.
    # - resources:            Set of resource hrefs (images/css/...) to bundle
    # - placeholder_endnotes: Array of {id:, target_title:, original_text:} for
    #                         cross-chapter links we couldn't copy (see
    #                         append_endnotes_section)
    # - copied_endnote_refs:  Hash of source_spine_href => [fragment_id, ...]
    #                         for note definitions to copy into the chapter
    # - extended_desc_hrefs:  Array of spine_hrefs to copy wholesale
    Collector = Struct.new(:resources, :placeholder_endnotes, :copied_endnote_refs, :extended_desc_hrefs) do
      def add_endnote_ref(source_href, fragment)
        list = (self.copied_endnote_refs[source_href] ||= [])
        list << fragment unless list.include?(fragment)
      end

      def add_extended_desc(href)
        extended_desc_hrefs << href unless extended_desc_hrefs.include?(href)
      end
    end

    def initialize(epub_root_path, output_dir)
      @epub_root  = epub_root_path
      @output_dir = output_dir
    end

    def build
      load_opf
      load_nav
      build_chapter_ranges
      assign_endnote_targets
      FileUtils.mkdir_p(@output_dir)
      @chapter_ranges.each_with_index { |chapter, idx| build_chapter_epub(chapter, idx) }
      # Reflect what actually got written to disk. A chapter's `<index>.epub`
      # may be missing if e.g. every spine file it wanted was absent (see
      # build_chapter_epub). `downloadable?` here is analogous to the file-
      # existence check that PDFEbook::Interval#downloadable? / EPub::Interval#downloadable?
      # do at ToC-cache time, but computed once, up front, from the same
      # source of truth that produced the chapter files.
      @chapter_ranges.each_with_index do |chapter, idx|
        chapter[:downloadable?] = File.exist?(File.join(@output_dir, "#{idx}.epub"))
      end
      @chapter_ranges
    end

    private

      # ---------------- Parsing ----------------

      def load_opf
        container_xml = File.read(File.join(@epub_root, 'META-INF', 'container.xml'))
        container_doc = Nokogiri::XML(container_xml).remove_namespaces!
        rootfile_node = container_doc.at_xpath('//rootfile')
        raise "EPUB at #{@epub_root} has no rootfile in container.xml" if rootfile_node.nil?

        @opf_path      = rootfile_node['full-path']        # e.g. 'OEBPS/content.opf'
        @opf_full_path = File.join(@epub_root, @opf_path)
        @opf_dir       = File.dirname(@opf_path)           # 'OEBPS' or 'EPUB' etc.
        @opf_dir_full  = File.dirname(@opf_full_path)

        @opf_doc_ns = Nokogiri::XML(File.read(@opf_full_path)).remove_namespaces!

        @manifest_items = {} # id => { href:, media_type:, properties: }
        @opf_doc_ns.xpath('//manifest/item').each do |item|
          @manifest_items[item['id']] = {
            href: item['href'],
            media_type: item['media-type'],
            properties: item['properties']
          }
        end
        # href (relative to opf_dir) => id
        @manifest_href_to_id = {}
        @manifest_items.each { |id, info| @manifest_href_to_id[info[:href]] = id }

        @spine_idrefs = @opf_doc_ns.xpath('//spine/itemref').map { |i| i['idref'] }
        @spine_href_to_index = {}
        @spine_idrefs.each_with_index do |idref, i|
          info = @manifest_items[idref]
          next if info.nil?
          @spine_href_to_index[info[:href]] = i
        end

        @opf_language = @opf_doc_ns.at_xpath('//metadata/language')&.text&.strip
        @opf_language = 'en' if @opf_language.blank?
        @opf_title = @opf_doc_ns.at_xpath('//metadata/title')&.text&.strip || ''
      end

      def load_nav
        nav_pair = @manifest_items.find { |_id, info| info[:properties]&.split(/\s+/)&.include?('nav') }
        raise "EPUB at #{@epub_root} has no navigation document (item with properties=\"nav\")" if nav_pair.nil?

        @nav_id   = nav_pair[0]
        @nav_href = nav_pair[1][:href] # relative to opf_dir
        @nav_full_path = File.join(@opf_dir_full, @nav_href)

        nav_doc = Nokogiri::XML(File.read(@nav_full_path)).remove_namespaces!
        toc_nav = nav_doc.at_xpath("//nav[@type='toc']") || nav_doc.at_xpath('//nav')
        raise "EPUB at #{@epub_root} nav document has no <nav> element" if toc_nav.nil?

        top_ol = toc_nav.at_xpath('./ol')
        raise "EPUB at #{@epub_root} nav has no top-level <ol>" if top_ol.nil?

        # Collect every <li> in the ToC (recursively, in document order), not just
        # top-level entries. Each entry that resolves to a known spine item
        # becomes its own downloadable chapter.
        @toc_entries = []
        top_ol.xpath('.//li').each do |li|
          a = li.at_xpath('./a[@href]')
          next if a.nil?
          href_raw = a['href']
          target, fragment = href_raw.split('#', 2)
          # Skip fragment-only ToC anchors (they have no file target of their own)
          next if target.blank?
          spine_href = resolve_href_to_opf_dir(target, File.dirname(@nav_href))
          next unless @spine_href_to_index.key?(spine_href)
          @toc_entries << {
            title: a.text.strip,
            spine_href: spine_href,
            spine_index: @spine_href_to_index[spine_href],
            # Retained so build_cfi can mirror EPub::Rendition#intervals' cfi format for CSB.
            href_raw: href_raw,
            href_fragment: fragment,
            # Nesting depth of this <li> in the ToC (top-level == 1). Used by
            # build_chapter_ranges to make a parent's chapter include all of
            # its nested descendants' spine files.
            depth: li.ancestors('li').length + 1
          }
        end
      end

      def build_chapter_ranges
        # A parent ToC entry's chapter includes all of its nested descendants'
        # spine items, matching the PDF chapter-splitting behavior. The range
        # therefore covers spine items from this entry's target up to (but not
        # including) the next later ToC entry whose depth is less-than-or-equal
        # to this entry's depth (i.e., the next sibling or ancestor-sibling).
        # Entries sharing a spine file with a neighboring same-or-shallower
        # entry produce a single-spine-item chapter.
        @chapter_ranges = @toc_entries.each_with_index.map do |entry, idx|
          start_idx = entry[:spine_index]
          next_sibling_or_shallower = @toc_entries[(idx + 1)..].to_a.find { |e| e[:depth] <= entry[:depth] }
          end_idx = next_sibling_or_shallower ? next_sibling_or_shallower[:spine_index] - 1 : @spine_idrefs.length - 1
          end_idx = start_idx if end_idx < start_idx
          spine_hrefs = (start_idx..end_idx).filter_map { |i| @manifest_items[@spine_idrefs[i]]&.dig(:href) }
          {
            # `title`, `level`, `cfi`, `downloadable?` are the keys consumed by
            # EbookTableOfContentsCache (see UnpackJob#cache_epub_toc) and match
            # the shape that Interval#to_h_for_toc produces for pdf_ebooks/epubs.
            title: entry[:title],
            level: entry[:depth],
            cfi: build_cfi(entry),
            # populated in `build` once the chapter file is written to disk
            downloadable?: false,
            start_spine_index: start_idx,
            end_spine_index: end_idx,
            spine_hrefs: spine_hrefs
          }
        end
      end

      # Mirror the cfi format produced by EPub::Rendition#intervals so that
      # cozy-sun-bear (the reader) can navigate to the same location whether
      # the cache was built from this service or from Rendition.
      def build_cfi(entry)
        if entry[:href_fragment].present?
          # Path from the epub root to the nav file's directory, e.g. "OEBPS".
          # Matches EPub::Rendition#file_url's behavior (which prepends the nav
          # dir and %23-escapes the fragment) — kept bug-compatible on purpose.
          nav_dir_from_root = File.dirname(File.join(@opf_dir, @nav_href))
          "/#{nav_dir_from_root}/#{entry[:href_raw].gsub('#', '%23')}"
        else
          idref = @manifest_href_to_id[entry[:spine_href]]
          # Rendition/Unmarshaller::Content uses a 1-based spine index for cfi;
          # @spine_href_to_index here is 0-based, so bump by one for parity.
          "/6/#{(entry[:spine_index] + 1) * 2}[#{idref}]!/4/1:0"
        end
      end

      def assign_endnote_targets
        # Map spine href -> first chapter index that contains it. Multiple ToC
        # entries can share a spine file; pick the first for endnote labeling.
        @href_to_chapter_index = {}
        @chapter_ranges.each_with_index do |chap, ci|
          chap[:spine_hrefs].each { |h| @href_to_chapter_index[h] ||= ci }
        end
      end

      # ---------------- Per-chapter build ----------------

      def build_chapter_epub(chapter, index) # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/BlockLength
        Dir.mktmpdir("epub-chapter-#{index}-") do |tmpdir| # rubocop:disable Metrics/BlockLength
          FileUtils.mkdir_p(File.join(tmpdir, 'META-INF'))
          opf_dir_tmp = File.join(tmpdir, @opf_dir)
          FileUtils.mkdir_p(opf_dir_tmp)

          File.write(File.join(tmpdir, 'META-INF', 'container.xml'), container_xml_content)

          resources = Set.new
          collector = Collector.new(resources, [], {}, [])

          # First pass: copy + rewrite each spine xhtml in this chapter
          chapter[:spine_hrefs].each do |spine_href|
            src = File.join(@opf_dir_full, spine_href)
            unless File.exist?(src)
              Rails.logger.warn("[EpubChaptersService] Spine file missing from disk, skipping: #{src}") if defined?(Rails)
              next
            end
            dst = File.join(opf_dir_tmp, spine_href)
            FileUtils.mkdir_p(File.dirname(dst))
            doc = Nokogiri::XML(File.read(src))
            rewrite_links(doc, spine_href, chapter, collector)
            collect_resources(doc, spine_href, resources)
            File.write(dst, doc.to_xml)
          end

          # Drop any spine hrefs whose underlying files don't actually exist on disk
          chapter = chapter.merge(spine_hrefs: chapter[:spine_hrefs].select { |h| File.exist?(File.join(opf_dir_tmp, h)) })
          next if chapter[:spine_hrefs].empty?

          # Append placeholder endnotes (if any) to the last (main) spine file
          if collector.placeholder_endnotes.any?
            last_href = chapter[:spine_hrefs].last
            last_path = File.join(opf_dir_tmp, last_href)
            doc = Nokogiri::XML(File.read(last_path))
            append_endnotes_section(doc, collector.placeholder_endnotes)
            File.write(last_path, doc.to_xml)
          end

          # Copy destination content for cross-file endnote references and
          # "extended description" links, adding those files to the chapter's
          # spine (after the main content).
          copied_hrefs = copy_referenced_endnote_files(collector, opf_dir_tmp, resources)
          copied_hrefs += copy_extended_description_files(collector, chapter, opf_dir_tmp, resources)
          chapter = chapter.merge(spine_hrefs: chapter[:spine_hrefs] + copied_hrefs) if copied_hrefs.any?

          # Copy referenced resources (preserving relative paths from opf_dir)
          resources.each do |res_href|
            src = File.join(@opf_dir_full, res_href)
            next unless File.exist?(src)
            dst = File.join(opf_dir_tmp, res_href)
            FileUtils.mkdir_p(File.dirname(dst))
            FileUtils.cp(src, dst)
          end

          # New nav.xhtml at original nav location
          nav_path_tmp = File.join(opf_dir_tmp, @nav_href)
          FileUtils.mkdir_p(File.dirname(nav_path_tmp))
          File.write(nav_path_tmp, build_nav_xhtml(chapter, index))

          # New content.opf
          opf_path_tmp = File.join(opf_dir_tmp, File.basename(@opf_path))
          File.write(opf_path_tmp, build_content_opf(chapter, index, resources))

          out_file = File.join(@output_dir, "#{index}.epub")
          FileUtils.rm_f(out_file)
          zip_epub(tmpdir, out_file)
        end
        # rubocop:enable Metrics/BlockLength
      end

      # ---------------- Link rewriting ----------------

      def rewrite_links(doc, current_spine_href, chapter, collector)
        current_dir = File.dirname(current_spine_href)
        placeholder_target_file = chapter[:spine_hrefs].last

        doc.css('a[href]').each do |a|
          href = a['href']
          next if href.blank?
          # fragment-only or external (mailto:, http(s)://, tel:, etc.) - leave alone
          next if href.start_with?('#')
          next if href.match?(%r{\A[a-zA-Z][a-zA-Z0-9+\-.]*:})

          target_path, fragment = href.split('#', 2)
          resolved = resolve_href_to_opf_dir(target_path, current_dir)

          # Internal-to-chapter link - keep as-is (the file is present in this chapter epub)
          next if chapter[:spine_hrefs].include?(resolved)

          # 1) Endnote reference into another file: remember which note to copy.
          #    The copied file keeps `resolved`'s path, so the href still resolves
          #    and needs no rewriting.
          if noteref?(a) && fragment.present?
            collector.add_endnote_ref(resolved, fragment)
            next
          end

          # 2) "Extended description" link: copy the whole target file in. Again
          #    the href keeps resolving because the file lands at `resolved`.
          if extended_description_link?(a)
            collector.add_extended_desc(resolved)
            next
          end

          # 3) Other cross-chapter link - convert to an in-chapter endnote
          add_placeholder_endnote(a, resolved, current_spine_href, placeholder_target_file, collector.placeholder_endnotes)
        end
      end

      def add_placeholder_endnote(anchor, resolved, current_spine_href, target_file, endnotes)
        target_chapter_idx = @href_to_chapter_index[resolved]
        target_title = if target_chapter_idx
                         @chapter_ranges[target_chapter_idx][:title]
                       else
                         'another section of the book'
                       end
        en_index = endnotes.length + 1
        en_id = "epub-chapter-endnote-#{en_index}"
        endnotes << { id: en_id, target_title: target_title, original_text: anchor.text.to_s.strip }

        new_href = if current_spine_href == target_file
                     "##{en_id}"
                   else
                     "#{rel_path_between(current_spine_href, target_file)}##{en_id}"
                   end
        anchor['href'] = new_href
        anchor['role'] = 'doc-noteref'
        anchor['epub:type'] = 'noteref'
      end

      # An endnote/footnote reference: `epub:type="noteref"` or `role="doc-noteref"`.
      def noteref?(anchor)
        epub_type_tokens(anchor).include?('noteref') ||
          anchor['role'].to_s.split(/\s+/).include?('doc-noteref')
      end

      # An "extended description" link is only reliably identifiable by the class
      # on its enclosing paragraph. Exclude the reciprocal "back" links (which
      # share the same paragraph class) so we don't treat them as forward links.
      def extended_description_link?(anchor)
        return false if anchor['role'].to_s.split(/\s+/).include?('doc-backlink')
        (enclosing_paragraph_classes(anchor) & EXTENDED_DESCRIPTION_CLASSES).any?
      end

      def enclosing_paragraph_classes(node)
        n = node.parent
        while n&.element?
          return n['class'].to_s.split(/\s+/) if n.name == 'p'
          n = n.parent
        end
        []
      end

      def epub_type_tokens(node)
        raw = node['epub:type'] || node.attribute_with_ns('type', EPUB_NS)&.value
        raw.to_s.split(/\s+/)
      end

      # ---------------- Copying destination content ----------------

      # Write a trimmed copy of each source file that holds note definitions this
      # chapter references, keeping only the referenced notes and the original
      # filename. Returns the hrefs written (to be appended to the spine).
      def copy_referenced_endnote_files(collector, opf_dir_tmp, resources)
        collector.copied_endnote_refs.filter_map do |source_href, fragments|
          src = File.join(@opf_dir_full, source_href)
          next unless File.exist?(src)

          doc = Nokogiri::XML(File.read(src))
          trim_to_referenced_notes(doc, fragments)
          collect_resources(doc, source_href, resources)

          dst = File.join(opf_dir_tmp, source_href)
          FileUtils.mkdir_p(File.dirname(dst))
          File.write(dst, doc.to_xml)
          source_href
        end
      end

      # Remove every note definition in `doc` whose id isn't in `wanted_ids`,
      # leaving surrounding structure (headers, container lists) intact.
      def trim_to_referenced_notes(doc, wanted_ids)
        wanted = wanted_ids.to_set
        nodes = note_definition_nodes(doc)
        nodes.each { |node| node.remove unless wanted.include?(node['id']) }
      end

      def note_definition_nodes(doc)
        typed = doc.xpath('//*[@id]').select { |n| (epub_type_tokens(n) & NOTE_DEFINITION_TYPES).any? }
        return typed if typed.any?

        # Fallback for vendors that don't type each note: <li id> inside a
        # recognizable endnotes/footnotes container.
        doc.xpath('//*[@id]').select do |n|
          n.name == 'li' && n.ancestors.any? { |anc| note_container?(anc) }
        end
      end

      def note_container?(node)
        (epub_type_tokens(node) & %w[footnotes endnotes rearnotes]).any? ||
          node['role'].to_s.split(/\s+/).include?('doc-endnotes')
      end

      # Copy each "extended description" target file verbatim (its reciprocal
      # back-link points at a file that lives in this chapter). Returns the hrefs
      # written (to be appended to the spine).
      def copy_extended_description_files(collector, chapter, opf_dir_tmp, resources)
        collector.extended_desc_hrefs.filter_map do |href|
          next if chapter[:spine_hrefs].include?(href)

          src = File.join(@opf_dir_full, href)
          next unless File.exist?(src)

          doc = Nokogiri::XML(File.read(src))
          collect_resources(doc, href, resources)

          dst = File.join(opf_dir_tmp, href)
          FileUtils.mkdir_p(File.dirname(dst))
          File.write(dst, doc.to_xml)
          href
        end
      end

      def append_endnotes_section(doc, endnotes)
        body = doc.at_xpath('//xmlns:body', xmlns: XHTML_NS) || doc.at_xpath('//body')
        return if body.nil?

        # Build a fragment in the XHTML namespace so it parses inside the body.
        ns_attr = body.namespace&.href ? %Q( xmlns="#{body.namespace.href}") : ''
        items = endnotes.map do |en|
          # The text below is plain text, so escape it.
          original_text = xml_escape(en[:original_text].to_s)
          target_title  = xml_escape(en[:target_title].to_s)
          %Q(<li id="#{en[:id]}" role="doc-endnote">Link to "#{original_text}" originally pointed to the section: #{target_title}.</li>)
        end.join("\n")

        fragment_xml = <<~SECTION
          <section#{ns_attr} role="doc-endnotes" aria-label="External link references">
            <h2>External Link References</h2>
            <p>The following links in this chapter originally pointed to other sections of the book that are not included in this downloaded chapter.</p>
            <ol>
            #{items}
            </ol>
          </section>
        SECTION

        fragment = Nokogiri::XML.fragment(fragment_xml)
        body.add_child(fragment)
      end

      # ---------------- Resource discovery ----------------

      def collect_resources(doc, spine_href, resources)
        current_dir = File.dirname(spine_href)

        # (tag, attribute) pairs that point at resources we need to bundle
        pairs = [
          ['img',    'src'],
          ['image',  'href'],
          ['audio',  'src'],
          ['video',  'src'],
          ['video',  'poster'],
          ['source', 'src'],
          ['script', 'src'],
          ['link',   'href']
        ]

        pairs.each do |tag, attr|
          doc.css(tag).each do |node|
            val = node[attr]
            push_resource(val, current_dir, resources)
          end
        end

        # image[xlink:href] (SVG)
        doc.xpath('//*[local-name()="image"]').each do |node|
          val = node['xlink:href'] || node.attribute_with_ns('href', 'http://www.w3.org/1999/xlink')&.value
          push_resource(val, current_dir, resources)
        end
      end

      def push_resource(val, current_dir, resources)
        return if val.blank?
        return if val.start_with?('#')
        return if val.match?(%r{\A[a-zA-Z][a-zA-Z0-9+\-.]*:})
        path = val.split('#').first.to_s.split('?').first
        return if path.blank?
        resources << resolve_href_to_opf_dir(path, current_dir)
      end

      # ---------------- OPF / nav generation ----------------

      def build_content_opf(chapter, index, resources)
        included_items = {}
        chapter[:spine_hrefs].each do |href|
          id = @manifest_href_to_id[href]
          included_items[id] = @manifest_items[id] if id
        end
        resources.each do |href|
          id = @manifest_href_to_id[href]
          included_items[id] = @manifest_items[id] if id
        end
        # always include the nav doc
        included_items[@nav_id] = @manifest_items[@nav_id]

        manifest_xml = included_items.map do |id, info|
          attrs = %Q(id="#{xml_escape(id)}" href="#{xml_escape(info[:href])}" media-type="#{xml_escape(info[:media_type])}")
          attrs += %Q( properties="#{xml_escape(info[:properties])}") if info[:properties].present?
          "    <item #{attrs}/>"
        end.join("\n")

        spine_xml = chapter[:spine_hrefs].map do |h|
          idref = @manifest_href_to_id[h]
          "    <itemref idref=\"#{xml_escape(idref)}\"/>"
        end.join("\n")

        modified = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
        unique_id = "urn:uuid:#{SecureRandom.uuid}"
        chapter_title  = xml_escape("#{@opf_title} - #{chapter[:title]}".strip.sub(/\A-\s*/, ''))
        language       = xml_escape(@opf_language)

        <<~OPF
          <?xml version="1.0" encoding="utf-8"?>
          <package xmlns="#{OPF_NS}" version="3.0" unique-identifier="pub-id">
            <metadata xmlns:dc="#{DC_NS}">
              <dc:identifier id="pub-id">#{xml_escape(unique_id)}</dc:identifier>
              <dc:title>#{chapter_title}</dc:title>
              <dc:language>#{language}</dc:language>
              <meta property="dcterms:modified">#{modified}</meta>
            </metadata>
            <manifest>
          #{manifest_xml}
            </manifest>
            <spine>
          #{spine_xml}
            </spine>
          </package>
        OPF
      end

      def build_nav_xhtml(chapter, chapter_idx)
        parent_entry = @toc_entries[chapter_idx]
        parent_depth = parent_entry[:depth]
        parent_title = xml_escape(chapter[:title])
        nav_dir = File.dirname(@nav_href)

        rel_to_nav = lambda do |href|
          rel = if nav_dir == '.' || nav_dir.empty?
                  href
                else
                  Pathname.new(href).relative_path_from(Pathname.new(nav_dir)).to_s
                end
          xml_escape(rel)
        end

        parent_rel = rel_to_nav.call(chapter[:spine_hrefs].first)

        # Contiguous descendants: entries immediately following this one whose
        # depth is strictly greater than the parent's. These are exactly the
        # entries that are also included in this chapter EPUB (see
        # build_chapter_ranges), so their nav links will resolve within the epub.
        descendants = @toc_entries[(chapter_idx + 1)..].to_a.take_while { |e| e[:depth] > parent_depth }
        subtree, _consumed = build_toc_subtree(descendants, 0, parent_depth + 1)

        children_ol = subtree.any? ? render_toc_subtree(subtree, rel_to_nav) : ''

        <<~NAV
          <?xml version="1.0" encoding="UTF-8"?>
          <html xmlns="#{XHTML_NS}" xmlns:epub="#{EPUB_NS}">
            <head>
              <meta charset="UTF-8"/>
              <title>#{parent_title}</title>
            </head>
            <body>
              <nav epub:type="toc" id="toc" role="doc-toc">
                <h1>Contents</h1>
                <ol>
                  <li><a href="#{parent_rel}">#{parent_title}</a>#{children_ol}</li>
                </ol>
              </nav>
            </body>
          </html>
        NAV
      end

      # Parse a flat list of contiguous descendant ToC entries into a nested
      # tree at `min_depth`. Returns [nodes, consumed_count] where each node is
      # [entry, children_nodes].
      def build_toc_subtree(entries, start_idx, min_depth)
        nodes = []
        i = start_idx
        while i < entries.length
          e = entries[i]
          break if e[:depth] < min_depth
          if e[:depth] == min_depth
            children, consumed = build_toc_subtree(entries, i + 1, min_depth + 1)
            nodes << [e, children]
            i = consumed
          else
            # deeper than min_depth without a parent at min_depth — treat as sibling at min_depth
            children, consumed = build_toc_subtree(entries, i + 1, e[:depth] + 1)
            nodes << [e, children]
            i = consumed
          end
        end
        [nodes, i]
      end

      def render_toc_subtree(nodes, rel_to_nav)
        items = nodes.map do |entry, children|
          href  = rel_to_nav.call(entry[:spine_href])
          title = xml_escape(entry[:title])
          inner = children.any? ? render_toc_subtree(children, rel_to_nav) : ''
          %(<li><a href="#{href}">#{title}</a>#{inner}</li>)
        end.join
        "<ol>#{items}</ol>"
      end

      def container_xml_content
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
              <rootfile full-path="#{xml_escape(@opf_path)}" media-type="application/oebps-package+xml"/>
            </rootfiles>
          </container>
        XML
      end

      # ---------------- Zip ----------------

      def zip_epub(src_dir, out_file)
        # Per the EPUB spec, `mimetype` MUST be the first entry in the archive
        # and MUST be STORED (uncompressed).
        Zip::OutputStream.open(out_file) do |zos|
          zos.put_next_entry('mimetype', nil, nil, Zip::Entry::STORED)
          zos.write('application/epub+zip')

          Dir.glob(File.join(src_dir, '**', '*'), File::FNM_DOTMATCH).sort.each do |path|
            next if File.directory?(path)
            rel = Pathname.new(path).relative_path_from(Pathname.new(src_dir)).to_s
            next if rel == 'mimetype'
            next if rel.split(File::SEPARATOR).any? { |seg| seg.start_with?('.') }
            zos.put_next_entry(rel)
            zos.write(File.binread(path))
          end
        end
      end

      # ---------------- Helpers ----------------

      def resolve_href_to_opf_dir(target_path, current_dir_relative_to_opf)
        return target_path if current_dir_relative_to_opf.nil? || current_dir_relative_to_opf == '.' || current_dir_relative_to_opf.empty?
        Pathname.new(File.join(current_dir_relative_to_opf, target_path)).cleanpath.to_s
      end

      def rel_path_between(from_file, to_file)
        from_dir = File.dirname(from_file)
        from_dir = '' if from_dir == '.'
        if from_dir.empty?
          to_file
        else
          Pathname.new(to_file).relative_path_from(Pathname.new(from_dir)).to_s
        end
      end

      def xml_escape(str)
        str.to_s
           .gsub('&', '&amp;')
           .gsub('<', '&lt;')
           .gsub('>', '&gt;')
           .gsub('"', '&quot;')
      end
  end
end
