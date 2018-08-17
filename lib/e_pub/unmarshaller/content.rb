# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Content
      private_class_method :new

      # Class Methods

      def self.from_rootfile_full_path(rootfile, full_path)
        return null_object unless rootfile&.instance_of?(Rootfile) && full_path&.instance_of?(String) && full_path.present?
        new(rootfile, full_path)
      end

      def self.null_object
        ContentNullObject.send(:new)
      end

      # Instance Methods

      def idref_with_index_from_href(href)
        href = href.split('#').first
        idref = href_idref[href]
        idref ||= base_href_idref[href]
        idref ||= up_one_href_idref[href]
        index = idref_index[idref]
        return [idref, index] if idref.present? && index.positive?
        ['', 0]
      end

      def chapter_from_title(title)
        chapter_list.chapters.each do |chapter|
          return chapter if chapter.title.casecmp?(title)
        end
        Chapter.null_object
      end

      def nav
        return @nav unless @nav.nil?
        begin
          nav_href = @content_doc.xpath(".//manifest/item[@properties='nav']").first.attributes["href"].value || ''
          @nav = Nav.from_content_nav_full_path(self, File.join(full_dir, nav_href))
        rescue StandardError => _e
          @nav = Nav.null_object
        end
        @nav
      end

      def chapter_list
        return @chapter_list unless @chapter_list.nil?
        begin
          chapter_list_href = @content_doc.xpath(".//manifest/item[@id='chapterlist']").first.attributes["href"].value || ''
          @chapter_list = ChapterList.from_content_chapter_list_full_path(self, File.join(full_dir, chapter_list_href))
        rescue StandardError => _e
          @chapter_list = ChapterList.null_object
        end
        @chapter_list
      end

      def cfi_from_href_anchor_tag(idref, index, toc_href)
        tag = toc_href.split('#').last

        chapter_href = @content_doc.xpath(".//manifest/item[@id='#{idref}']").first.attributes["href"].value
        chapter = File.join(File.dirname(@full_path), chapter_href)
        doc = Nokogiri::XML::Document.parse(File.open(chapter)).remove_namespaces!
        node = doc.at_css(%([id="#{tag}"]))

        indexes = []
        this = node

        while this && this.name != "body"
          siblings = this.parent.element_children
          idx = siblings.index(this)

          indexes << if this.text?
                       idx + 1
                     else
                       (idx + 1) * 2
                     end

          indexes[-1] = "#{indexes[-1]}[#{this['id']}]" if this['id']

          this = this.parent
        end
        indexes.reverse!

        return "/6/#{index * 2}[#{idref}]!/4/1:0" if indexes.length.zero?

        "/6/#{index * 2}[#{idref}]!/4/#{indexes.join('/')}"
      end

      private

        def initialize(rootfile, full_path)
          @rootfile = rootfile
          @full_path = full_path
          begin
            @content_doc = Nokogiri::XML::Document.parse(File.open(@full_path)).remove_namespaces!
          rescue StandardError => _e
            @content_doc = Nokogiri::XML::Document.parse(nil)
          end
        end

        def full_dir
          @full_dir ||= File.dirname(@full_path)
        end

        def href_idref
          return @href_idref unless @href_idref.nil?
          @href_idref = {}
          @content_doc.xpath(".//manifest/item").each do |item|
            href = item.attribute('href').value
            idref = item.attribute('id').value
            @href_idref[href] = idref if href.present? && idref.present?
          end
          @href_idref
        end

        def base_href_idref
          return @base_href_idref unless @base_href_idref.nil?
          @base_href_idref = {}
          href_idref.each do |href, idref|
            base_href = File.basename(href)
            @base_href_idref[base_href] = idref
          end
          @base_href_idref
        end

        def up_one_href_idref
          return @up_one_href_idref unless @up_one_href_idref.nil?
          @up_one_href_idref = {}
          href_idref.each do |href, idref|
            up_one_href = "../#{href}"
            @up_one_href_idref[up_one_href] = idref
          end
          @up_one_href_idref
        end

        def idref_index
          return @idref_index unless @idref_index.nil?
          @idref_index = {}
          index = 0
          @content_doc.xpath(".//spine/itemref").each do |itemref|
            idref = itemref.attribute('idref').value
            index += 1
            @idref_index[idref] = index if idref.present?
          end
          @idref_index
        end
    end

    class ContentNullObject < Content
      private_class_method :new

      private

        def initialize
          super(Rootfile.null_object, '')
        end
    end
  end
end
