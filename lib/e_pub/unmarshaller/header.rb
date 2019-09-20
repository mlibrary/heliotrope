# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Header
      private_class_method :new

      # Class Methods

      def self.from_toc_anchor_element(toc, anchor_element)
        return null_object unless toc&.instance_of?(TOC) && anchor_element&.instance_of?(Nokogiri::XML::Element)
        new(toc, anchor_element)
      end

      def self.null_object
        HeaderNullObject.send(:new)
      end

      # Instance Methods

      def href
        @href ||= @anchor_element.attribute('href')&.value || ''
      end

      def text
        @text ||= @anchor_element.text || ''
      end

      def depth
        @depth ||= @anchor_element.ancestors('li').length || 0
      end

      private
        def initialize(toc, anchor_element)
          @toc = toc
          @anchor_element = anchor_element
        end
    end

    class HeaderNullObject < Header
      private_class_method :new

      private
        def initialize
          super(TOC.null_object, Nokogiri::XML::Element.new('a', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
