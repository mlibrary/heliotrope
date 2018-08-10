# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Content
      private_class_method :new

      # Class Methods

      def self.null_object
        ContentNullObject.send(:new)
      end

      def self.from_full_path(full_path)
        return null_object unless full_path&.instance_of?(String) && full_path.present?
        new(full_path)
      end

      # Instance Methods

      def full_dir
        @full_dir ||= File.dirname(@full_path)
      end

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

      def nav
        return @nav unless @nav.nil?
        begin
          nav_href = @content_doc.xpath(".//manifest/item[@properties='nav']").first.attributes["href"].value || 'nav.xhtml'
          @nav = Nav.from_manifest_item_nav_href(File.join(full_dir, nav_href))
        rescue StandardError => _e
          @nav = Nav.null_object
        end
        @nav
      end

      private

        def initialize(full_path)
          @full_path = full_path
          begin
            @content_doc = Nokogiri::XML::Document.parse(File.open(@full_path)).remove_namespaces!
          rescue StandardError => _e
            @content_doc = Nokogiri::XML::Document.parse(nil)
          end
        end
    end

    class ContentNullObject < Content
      private_class_method :new

      private

        def initialize
          super('./full/path/content.opf')
        end
    end
  end
end
