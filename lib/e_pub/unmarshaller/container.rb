# frozen_string_literal: true

module EPub
  module Unmarshaller
    class Container
      private_class_method :new

      attr_reader :root_path

      # Class Methods

      def self.null_object
        ContainerNullObject.send(:new)
      end

      def self.from_root_path(root_path)
        return null_object unless root_path.present? && root_path.instance_of?(String) && Dir.exist?(root_path)
        new(root_path)
      end

      # Instance Methods

      def rootfile_elements
        @rootfile_elements ||= @container_doc.xpath(".//rootfile")
      end

      private

        def initialize(root_path)
          @root_path = root_path
          begin
            container_path = File.join(@root_path, 'META-INF/container.xml')
            @container_doc = Nokogiri::XML::Document.parse(File.open(container_path)).remove_namespaces!
          rescue StandardError => _e
            @container_doc = Nokogiri::XML::Document.parse(nil)
          end
        end
    end

    class ContainerNullObject < Container
      private_class_method :new

      private

        def initialize
          super('.')
        end
    end
  end
end
