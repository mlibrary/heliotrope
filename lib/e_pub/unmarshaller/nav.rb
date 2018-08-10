# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Nav
      private_class_method :new

      # Class Methods

      def self.null_object
        NavNullObject.send(:new)
      end

      def self.from_manifest_item_nav_href(manifest_item_nav_href)
        return null_object unless manifest_item_nav_href&.instance_of?(String) && manifest_item_nav_href.present?
        new(manifest_item_nav_href)
      end

      # Instance Methods

      def tocs
        return @tocs unless @tocs.nil?
        @tocs = []
        @nav_doc.xpath(".//nav[@type='toc']").each do |toc|
          @tocs << TOC.from_nav_toc_element(toc)
        end
        @tocs
      end

      private

        def initialize(manifest_item_nav_href)
          @manifest_item_nav_href = manifest_item_nav_href
          begin
            @nav_doc = Nokogiri::XML::Document.parse(File.open(@manifest_item_nav_href)).remove_namespaces!
          rescue StandardError => _e
            @nav_doc = Nokogiri::XML::Document.parse(nil)
          end
        end
    end

    class NavNullObject < Nav
      private_class_method :new

      private

        def initialize
          super('nav.xhtml')
        end
    end
  end
end
