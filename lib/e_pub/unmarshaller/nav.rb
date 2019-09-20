# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Nav
      private_class_method :new

      attr_reader :full_path

      # Class Methods

      def self.from_content_nav_full_path(content, full_path)
        return null_object unless content&.instance_of?(Content) && full_path&.instance_of?(String) && full_path.present?
        new(content, full_path)
      end

      def self.null_object
        NavNullObject.send(:new)
      end

      # Instance Methods

      def tocs
        return @tocs unless @tocs.nil?
        @tocs = []
        @nav_doc.xpath(".//nav[@type='toc']").each do |toc|
          @tocs << TOC.from_nav_toc_element(self, toc)
        end
        @tocs
      end

      private
        def initialize(content, full_path)
          @content = content
          @full_path = full_path
          begin
            @nav_doc = Nokogiri::XML::Document.parse(File.open(@full_path)).remove_namespaces!
          rescue StandardError => _e
            @nav_doc = Nokogiri::XML::Document.parse(nil)
          end
        end
    end

    class NavNullObject < Nav
      private_class_method :new

      private
        def initialize
          super(Content.null_object, '')
        end
    end
  end
end
