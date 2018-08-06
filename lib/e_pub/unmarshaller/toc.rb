# frozen_string_literal: true

module EPub
  module Unmarshaller
    class TOC
      private_class_method :new

      # Class Methods

      def self.null_object
        TOCNullObject.send(:new)
      end

      def self.from_nav_toc_element(toc_element)
        return null_object unless toc_element&.instance_of?(Nokogiri::XML::Element)
        new(toc_element)
      end

      # Instance Methods

      def id
        @toc_element["id"] || 0
      end

      def headers
        return headers unless @headers.nil?
        @headers = []
        @toc_element.xpath('.//a').each do |anchor|
          @headers << Header.from_toc_anchor_element(anchor)
        end
        @headers
      end

      private

        def initialize(toc_element)
          @toc_element = toc_element
        end
    end

    class TOCNullObject < TOC
      private_class_method :new

      private

        def initialize
          super(Nokogiri::XML::Element.new('toc', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
