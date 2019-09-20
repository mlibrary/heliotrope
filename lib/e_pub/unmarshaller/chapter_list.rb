# frozen_string_literal: true

module EPub
  module Unmarshaller
    class ChapterList
      private_class_method :new

      attr_reader :full_path

      # Class Methods

      def self.from_content_chapter_list_full_path(content, full_path)
        return null_object unless content&.instance_of?(Content) && full_path&.instance_of?(String) && full_path.present?
        new(content, full_path)
      end

      def self.null_object
        ChapterListNullObject.send(:new)
      end

      # Instance Methods

      def chapters
        return @chapters unless @chapters.nil?
        @chapters = []
        @chapter_list_doc.xpath('.//span').each do |span|
          @chapters << Chapter.from_chapter_list_span_element(self, span)
        end
        @chapters
      end

      private
        def initialize(content, full_path)
          @content = content
          @full_path = full_path
          begin
            @chapter_list_doc = Nokogiri::XML::Document.parse(File.open(@full_path)).remove_namespaces!
          rescue StandardError => _e
            @chapter_list_doc = Nokogiri::XML::Document.parse(nil)
          end
        end
    end

    class ChapterListNullObject < ChapterList
      private_class_method :new

      private
        def initialize
          super(Content.null_object, '')
        end
    end
  end
end
