# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Chapter
      private_class_method :new

      delegate :full_path, to: :@chapter_list

      # Class Methods
      #
      def self.from_chapter_list_span_element(chapter_list, span_element)
        return null_object unless chapter_list&.instance_of?(ChapterList) && span_element&.instance_of?(Nokogiri::XML::Element)
        new(chapter_list, span_element)
      end

      def self.null_object
        ChapterNullObject.send(:new)
      end

      # Instance Methods

      def title
        @title ||= @span_element.text || ''
      end

      def pages
        return @pages unless @pages.nil?
        @pages = []
        if @span_element.parent.present?
          @span_element.parent.xpath(".//a").each do |anchor|
            @pages << Page.from_chapter_span_parent_anchor_element(self, anchor)
          end
        end
        @pages
      end

      def downloadable_pages
        return @pages unless @pages.nil?
        @pages = []
        if @span_element.parent.present? && ["chapter", "frontmatter", "backmatter"].include?(@span_element.parent.attributes['class']&.value)
          @span_element.parent.xpath(".//a").each do |anchor|
            @pages << Page.from_chapter_span_parent_anchor_element(self, anchor)
          end
        end
        @pages
      end

      private

        def initialize(chapter_list, span_element)
          @chapter_list = chapter_list
          @span_element = span_element
        end
    end

    class ChapterNullObject < Chapter
      private_class_method :new

      private

        def initialize
          super(ChapterList.null_object, Nokogiri::XML::Element.new('span', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
