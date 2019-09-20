# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Page
      private_class_method :new

      # Class Methods
      #
      def self.from_chapter_span_parent_anchor_element(chapter, anchor_element)
        return null_object unless chapter&.instance_of?(Chapter) && anchor_element&.instance_of?(Nokogiri::XML::Element)
        new(chapter, anchor_element)
      end

      def self.null_object
        PageNullObject.send(:new)
      end

      # Instance Methods

      def image
        @image ||= if @page_doc.xpath(".//img").first&.attribute('src')&.value
          File.join(File.dirname(@full_path), @page_doc.xpath(".//img").first.attribute('src').value)
        else
          ''
        end
      end

      private
        def initialize(chapter, anchor_element)
          @chapter = chapter
          @anchor_element = anchor_element
          if @anchor_element.attribute('href')&.value
            @full_path = File.join(File.dirname(@chapter.full_path), @anchor_element.attribute('href').value)
            begin
              @page_doc = Nokogiri::XML::Document.parse(File.open(@full_path)).remove_namespaces!
            rescue StandardError => _e
              @page_doc = Nokogiri::XML::Document.parse(nil)
            end
          else
            @full_path = ''
            @page_doc = Nokogiri::XML::Document.parse(nil)
          end
        end
    end

    class PageNullObject < Page
      private_class_method :new

      private
        def initialize
          super(Chapter.null_object, Nokogiri::XML::Element.new('a', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
