# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'
require 'pathname'

# Migrates an *unpacked* EPUB 2.x publication in place so that it conforms to
# EPUB 3.3 (EPUBCheck 5.3.0 passes with zero errors), and makes a first-pass
# effort at the "easy" DAISY Ace accessibility rules (currently just
# `link-in-text-block`).
#
# This is intended to be called from UnpackJob right after an EPUB is unzipped:
# the migration is a no-op unless the publication declares itself as EPUB 2.x,
# so it is safe to call unconditionally for every EPUB.
#
# What it does (all in place, on the already-unpacked directory):
#   * package.opf
#       - bumps <package version="2.0"> to "3.0"
#       - removes the EPUB2-only OPF-namespace metadata attributes that are not
#         allowed in EPUB 3 (opf:scheme / opf:role / opf:file-as / opf:event /
#         opf:authority), which EPUBCheck flags as RSC-005 errors
#       - guarantees exactly one <meta property="dcterms:modified"> (required by
#         EPUB 3's release-identifier rules)
#       - guarantees a Navigation Document exists in the manifest, adding one
#         (item with properties="nav") when the book only had an NCX
#   * a generated Navigation Document (XHTML) built from the NCX navMap, when
#     the book didn't already have one
#   * every XHTML/HTML content document
#       - replaces the irregular XHTML 1.1 DOCTYPE with the EPUB3 `<!DOCTYPE
#         html>` (EPUBCheck HTM-004)
#       - normalizes any `<meta http-equiv="Content-Type">` to the only value
#         EPUB3/HTML5 allows: "text/html; charset=utf-8" (EPUBCheck RSC-005)
#       - injects a small stylesheet rule that underlines in-text links so they
#         are distinguishable without relying on colour (DAISY Ace
#         `link-in-text-block`)
#
# The NCX itself is retained (it remains valid as a "superseded" navigation
# aid in EPUB 3), so existing `toc="ncx"` spine references keep working.
module EpubConversionService
  module_function

  # Migrate the unpacked EPUB rooted at `epub_root_path` from EPUB 2.x to
  # EPUB 3.3 in place. Returns true if a migration was performed, false if the
  # publication was not EPUB 2.x (and therefore left untouched).
  def migrate(epub_root_path)
    Migrator.new(epub_root_path).migrate
  end

  # True when the unpacked EPUB at `epub_root_path` declares itself EPUB 2.x.
  def epub2?(epub_root_path)
    Migrator.new(epub_root_path).epub2?
  end

  class Migrator
    OPF_NS   = 'http://www.idpf.org/2007/opf'
    XHTML_NS = 'http://www.w3.org/1999/xhtml'
    EPUB_NS  = 'http://www.idpf.org/2007/ops'

    # OPF-namespace attributes that were legal on EPUB2 metadata elements but
    # are rejected by EPUBCheck under EPUB3 rules.
    DISALLOWED_OPF_ATTRS = %w[scheme role file-as event authority].freeze

    # Marker embedded in the injected <style> so the migration is idempotent.
    LINK_STYLE_MARKER = 'epub-conversion-link-underline'

    CONTENT_DOC_EXTENSIONS = %w[.xhtml .html .htm].freeze

    def initialize(epub_root_path)
      @epub_root = epub_root_path
    end

    def epub2?
      load_opf
      @package_version.to_s.strip.start_with?('2')
    rescue StandardError => e
      log_warn("could not determine EPUB version for #{@epub_root}: #{e.message}")
      false
    end

    def migrate
      load_opf
      return false unless @package_version.to_s.strip.start_with?('2')

      upgrade_opf
      migrate_content_documents
      true
    rescue StandardError => e
      log_error("migration failed for #{@epub_root}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      raise
    end

    private

      # ---------------- OPF loading ----------------

      def load_opf
        container_xml = File.read(File.join(@epub_root, 'META-INF', 'container.xml'))
        container_doc = Nokogiri::XML(container_xml).remove_namespaces!
        rootfile_node = container_doc.at_xpath('//rootfile')
        raise "EPUB at #{@epub_root} has no rootfile in container.xml" if rootfile_node.nil?

        @opf_path      = rootfile_node['full-path']  # e.g. 'OEBPS/package.opf' or 'book.opf'
        @opf_full_path = File.join(@epub_root, @opf_path)
        @opf_dir       = File.dirname(@opf_path)
        @opf_dir_full  = File.dirname(@opf_full_path)

        @opf_doc = Nokogiri::XML(File.read(@opf_full_path))
        package = @opf_doc.at_xpath('//*[local-name()="package"]')
        raise "EPUB at #{@epub_root} has no <package> element" if package.nil?

        @package_node    = package
        @package_version = package['version']
      end

      # ---------------- OPF upgrade ----------------

      def upgrade_opf
        @package_node['version'] = '3.0'
        strip_disallowed_opf_attributes
        ensure_dcterms_modified
        ensure_nav_document
        File.write(@opf_full_path, @opf_doc.to_xml)
      end

      def strip_disallowed_opf_attributes
        metadata = @opf_doc.at_xpath('//*[local-name()="metadata"]')
        return if metadata.nil?

        (metadata.xpath('.//*').to_a + [metadata]).each do |node|
          node.attribute_nodes.each do |attr|
            next unless attr.namespace&.prefix == 'opf'
            attr.remove if DISALLOWED_OPF_ATTRS.include?(attr.node_name)
          end
        end
      end

      def ensure_dcterms_modified
        metadata = @opf_doc.at_xpath('//*[local-name()="metadata"]')
        return if metadata.nil?

        metadata.xpath('.//*[local-name()="meta"][@property="dcterms:modified"]').each(&:remove)
        meta = Nokogiri::XML::Node.new('meta', @opf_doc)
        meta['property'] = 'dcterms:modified'
        meta.content = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
        meta.namespace = @package_node.namespace
        metadata.add_child(meta)
      end

      # Guarantee the manifest advertises a Navigation Document (an item with
      # properties="nav"). EPUB 2.x books only have an NCX, so when none is
      # present we generate one from the NCX and register it.
      def ensure_nav_document
        manifest = @opf_doc.at_xpath('//*[local-name()="manifest"]')
        raise "EPUB at #{@epub_root} has no <manifest> element" if manifest.nil?

        existing_nav = manifest.xpath('./*[local-name()="item"]').find do |item|
          item['properties'].to_s.split(/\s+/).include?('nav')
        end
        return if existing_nav

        nav_href = generate_nav_document
        item = Nokogiri::XML::Node.new('item', @opf_doc)
        item['id']         = unique_manifest_id(manifest, 'nav')
        item['href']       = nav_href
        item['media-type'] = 'application/xhtml+xml'
        item['properties'] = 'nav'
        item.namespace = @package_node.namespace
        manifest.add_child(item)
      end

      def unique_manifest_id(manifest, base)
        taken = manifest.xpath('.//@id').map(&:value).to_set
        return base unless taken.include?(base)

        i = 1
        i += 1 while taken.include?("#{base}#{i}")
        "#{base}#{i}"
      end

      # ---------------- Navigation Document generation ----------------

      # Build an XHTML Navigation Document from the NCX and write it next to the
      # OPF. Returns the nav href relative to the OPF directory.
      def generate_nav_document
        nav_href = available_nav_filename
        nav_full = File.join(@opf_dir_full, nav_href)
        title    = xml_escape(book_title)
        list_xml = nav_list_xml

        File.write(nav_full, <<~NAV)
          <?xml version="1.0" encoding="UTF-8"?>
          <html xmlns="#{XHTML_NS}" xmlns:epub="#{EPUB_NS}" lang="#{xml_escape(book_language)}" xml:lang="#{xml_escape(book_language)}">
            <head>
              <meta charset="utf-8"/>
              <title>#{title}</title>
            </head>
            <body>
              <nav epub:type="toc" id="toc" role="doc-toc" aria-label="Table of contents">
                <h1>#{title}</h1>
          #{list_xml}
              </nav>
            </body>
          </html>
        NAV
        nav_href
      end

      # A nav filename (relative to the OPF dir) that doesn't collide with an
      # existing manifest href or file on disk.
      def available_nav_filename
        base = 'nav'
        candidate = "#{base}.xhtml"
        i = 1
        while File.exist?(File.join(@opf_dir_full, candidate))
          candidate = "#{base}#{i}.xhtml"
          i += 1
        end
        candidate
      end

      def book_title
        @opf_doc.at_xpath('//*[local-name()="metadata"]/*[local-name()="title"]')&.text&.strip.presence || 'Table of Contents'
      end

      def book_language
        @opf_doc.at_xpath('//*[local-name()="metadata"]/*[local-name()="language"]')&.text&.strip.presence || 'en'
      end

      # Render the nav <ol> from the NCX navMap, preserving nesting. Falls back
      # to the spine reading order when there is no usable NCX.
      def nav_list_xml
        points = ncx_nav_points
        points = spine_nav_points if points.empty?
        render_nav_points(points, 3)
      end

      # Parse the NCX navMap into nested [{title:, href:, children: [...]}, ...].
      def ncx_nav_points
        ncx_full = ncx_path
        return [] if ncx_full.nil? || !File.exist?(ncx_full)

        ncx_doc = Nokogiri::XML(File.read(ncx_full)).remove_namespaces!
        nav_map = ncx_doc.at_xpath('//navMap')
        return [] if nav_map.nil?

        ncx_dir = File.dirname(ncx_full)
        parse_nav_points(nav_map.xpath('./navPoint'), ncx_dir)
      end

      def parse_nav_points(nodes, ncx_dir)
        nodes.map do |np|
          label = np.at_xpath('./navLabel/text')&.text.to_s.strip
          src   = np.at_xpath('./content/@src')&.value.to_s.strip
          {
            title: label,
            href: rebase_href_to_opf_dir(src, ncx_dir),
            children: parse_nav_points(np.xpath('./navPoint'), ncx_dir)
          }
        end
      end

      def spine_nav_points
        manifest = {}
        @opf_doc.xpath('//*[local-name()="manifest"]/*[local-name()="item"]').each do |item|
          manifest[item['id']] = item['href']
        end
        @opf_doc.xpath('//*[local-name()="spine"]/*[local-name()="itemref"]').each_with_index.filter_map do |itemref, idx|
          href = manifest[itemref['idref']]
          next if href.nil?
          { title: "Section #{idx + 1}", href: href, children: [] }
        end
      end

      def render_nav_points(points, indent_spaces)
        return '' if points.empty?

        pad = ' ' * indent_spaces
        items = points.map do |pt|
          title = xml_escape(pt[:title].presence || 'Untitled')
          href  = xml_escape(pt[:href])
          child = render_nav_points(pt[:children], indent_spaces + 4)
          if child.empty?
            "#{pad}  <li><a href=\"#{href}\">#{title}</a></li>"
          else
            "#{pad}  <li><a href=\"#{href}\">#{title}</a>\n#{child}\n#{pad}  </li>"
          end
        end.join("\n")
        "#{pad}<ol>\n#{items}\n#{pad}</ol>"
      end

      def ncx_path
        # Prefer the manifest's declared NCX (media-type application/x-dtbncx+xml),
        # falling back to the spine's toc idref, then any *.ncx in the manifest.
        item = @opf_doc.at_xpath('//*[local-name()="manifest"]/*[local-name()="item"][@media-type="application/x-dtbncx+xml"]')
        item ||= ncx_item_from_spine_toc
        item ||= @opf_doc.xpath('//*[local-name()="manifest"]/*[local-name()="item"]').find { |i| i['href'].to_s.downcase.end_with?('.ncx') }
        return nil if item.nil?

        File.join(@opf_dir_full, item['href'])
      end

      def ncx_item_from_spine_toc
        toc_id = @opf_doc.at_xpath('//*[local-name()="spine"]/@toc')&.value
        return nil if toc_id.nil?
        @opf_doc.at_xpath(%(//*[local-name()="manifest"]/*[local-name()="item"][@id="#{toc_id}"]))
      end

      # ---------------- Content document rewriting ----------------

      def migrate_content_documents
        content_document_paths.each do |path|
          original = File.read(path)
          updated  = rewrite_content_document(original)
          File.write(path, updated) if updated != original
        rescue StandardError => e
          log_warn("could not rewrite content document #{path}: #{e.message}")
        end
      end

      def content_document_paths
        Dir.glob(File.join(@epub_root, '**', '*')).select do |path|
          File.file?(path) && CONTENT_DOC_EXTENSIONS.include?(File.extname(path).downcase)
        end
      end

      def rewrite_content_document(content)
        content = fix_doctype(content)
        content = fix_content_type_meta(content)
        inject_link_style(content)
      end

      # Replace an irregular DOCTYPE (e.g. XHTML 1.1) with the EPUB3 `<!DOCTYPE
      # html>`. Leaves an already-correct/absent DOCTYPE alone.
      def fix_doctype(content)
        content.sub(/<!DOCTYPE\s+[^>]*>/i) do |doctype|
          doctype.match?(/\A<!DOCTYPE\s+html\s*>\z/i) ? doctype : '<!DOCTYPE html>'
        end
      end

      # EPUB3/HTML5 only permits `content="text/html; charset=utf-8"` on a
      # Content-Type http-equiv meta. Normalize any such meta regardless of
      # attribute order.
      def fix_content_type_meta(content)
        content.gsub(/<meta\b[^>]*\bhttp-equiv\s*=\s*(["'])content-type\1[^>]*>/i) do
          '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>'
        end
      end

      # Underline in-text links so they're distinguishable without colour
      # (DAISY Ace `link-in-text-block`). Idempotent via LINK_STYLE_MARKER.
      def inject_link_style(content)
        return content if content.include?(LINK_STYLE_MARKER)
        return content unless content.match?(/<\/head>/i)

        style = %(<style type="text/css">/* #{LINK_STYLE_MARKER} */ a[href] { text-decoration: underline; }</style>)
        content.sub(/<\/head>/i) { "#{style}</head>" }
      end

      # ---------------- Helpers ----------------

      # Resolve an href that is relative to `from_dir_full` (an absolute dir on
      # disk) into one relative to the OPF directory.
      def rebase_href_to_opf_dir(href, from_dir_full)
        return href if href.blank?
        target_path, fragment = href.split('#', 2)
        return href if target_path.blank? # fragment-only

        absolute = Pathname.new(File.expand_path(File.join(from_dir_full, target_path)))
        rel = absolute.relative_path_from(Pathname.new(File.expand_path(@opf_dir_full))).to_s
        fragment ? "#{rel}##{fragment}" : rel
      end

      def xml_escape(str)
        str.to_s
           .gsub('&', '&amp;')
           .gsub('<', '&lt;')
           .gsub('>', '&gt;')
           .gsub('"', '&quot;')
      end

      def log_warn(message)
        Rails.logger.warn("[EpubConversionService] #{message}") if defined?(Rails)
      end

      def log_error(message)
        Rails.logger.error("[EpubConversionService] #{message}") if defined?(Rails)
      end
  end
end
