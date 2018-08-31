# frozen_string_literal: true

module EPub
  module Marshaller
    class PDF
      private_class_method :new

      # Class Methods

      def self.from_publication(publication)
        return null_object unless publication.instance_of?(EPub::Publication)
        new(publication)
      end

      def self.from_publication_section(publication, section)
        return null_object unless publication.instance_of?(EPub::Publication) && section.instance_of?(EPub::Section)
        new(publication, section)
      end

      def self.null_object
        PDFNullObject.send(:new)
      end

      # Instance Methods

      def document
        # In Prawn, "LETTER" is 8.5x11 which is 612x792
        doc = Prawn::Document.new(page_size: "LETTER", page_layout: :portrait, margin: 50)
        if @publication.multi_rendition?
          @publication.renditions.each do |rendition|
            next unless /page scan/i.match?(rendition.label)
            rendition.sections.each do |section|
              next unless section.cfi == @section.cfi
              next unless section.title == @section.title
              section.pages.each do |page|
                doc.image page.image, fit: [512, 692] # minus 100 for the margin
              end
            end
          end
        end
        doc
      end

      private

        def initialize(publication, section = EPub::Section.null_object)
          @publication = publication
          @section = section
        end
    end

    class PDFNullObject < PDF
      private_class_method :new

      private

        def initialize
          super(EPub::Publication.null_object)
        end
    end
  end
end
