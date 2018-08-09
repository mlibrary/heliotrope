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
        idref = ''
        @content_doc.xpath(".//manifest/item").each do |item|
          next unless /#{href}/.match?(item.attribute('href').value)
          idref = item.attribute('id').value
          break
        end
        index = 0
        @content_doc.xpath(".//spine/itemref").each do |itemref|
          index += 1
          next unless idref.to_s == itemref.attribute('idref').value
          break
        end
        [idref, index]
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
