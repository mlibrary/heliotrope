# frozen_string_literal: true

module EPub
  module Unmarshaller
    class TOC
      private_class_method :new

      # Class Methods

      def self.from_nav_toc_element(nav, toc_element)
        return null_object unless nav&.instance_of?(Nav) && toc_element&.instance_of?(Nokogiri::XML::Element)
        new(nav, toc_element)
      end

      def self.null_object
        TOCNullObject.send(:new)
      end

      # Instance Methods

      def id
        @toc_element["id"] || "toc"
      end

      def headers
        return headers unless @headers.nil?
        @headers = []
        @toc_element.xpath('.//a').each do |anchor|
          @headers << Header.from_toc_anchor_element(self, anchor)
        end
        @headers
      end

      private
        def initialize(nav, toc_element)
          @nav = nav
          @toc_element = toc_element
        end
    end

    class TOCNullObject < TOC
      private_class_method :new

      private
        def initialize
          super(Nav.null_object, Nokogiri::XML::Element.new('toc', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
