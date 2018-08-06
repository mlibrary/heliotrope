# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Header
      private_class_method :new

      # Class Methods
      def self.from_toc_anchor_element(anchor_element)
        return null_object unless anchor_element&.instance_of?(Nokogiri::XML::Element)
        new(anchor_element)
      end

      def self.null_object
        HeaderNullObject.send(:new)
      end

      # Instance Methods

      def href
        @href ||= @anchor_element.attribute('href')&.value || 'href.xhtml'
      end

      def text
        @text ||= @anchor_element.text
      end

      def depth
        @depth ||= @anchor_element.ancestors('li').length
      end

      private

        def initialize(anchor_element)
          @anchor_element = anchor_element
        end
    end

    class HeaderNullObject < Header
      private_class_method :new

      private

        def initialize
          super(Nokogiri::XML::Element.new('a', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
