# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Rootfile
      private_class_method :new

      # Class Methods

      def self.from_container_rootfile_element(container, rootfile_element)
        return null_object unless container&.instance_of?(Container) && rootfile_element&.instance_of?(Nokogiri::XML::Element)
        new(container, rootfile_element)
      end

      def self.null_object
        RootfileNullObject.send(:new)
      end

      # Instance Methods

      def label
        @label ||= @rootfile_element&.attribute('label')&.text || ''
      end

      def content
        return @content unless @content.nil?
        full_path = if @rootfile_element&.attribute('full-path')&.value
                      File.join(@container.root_path, @rootfile_element.attribute('full-path').value)
                    else
                      ''
                    end
        @content = Content.from_rootfile_full_path(self, full_path)
      end

      private

        def initialize(container, rootfile_element)
          @container = container
          @rootfile_element = rootfile_element
        end
    end

    class RootfileNullObject < Rootfile
      private_class_method :new

      private

        def initialize
          super(Container.null_object, Nokogiri::XML::Element.new('rootfile', Nokogiri::XML::Document.parse(nil)))
        end
    end
  end
end
