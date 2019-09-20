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

      def self.from_publication_interval(publication, interval)
        return null_object unless publication.instance_of?(EPub::Publication) && interval.instance_of?(EPub::Interval)
        new(publication, interval)
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
            rendition.intervals.each do |interval|
              next unless interval.cfi == @interval.cfi
              next unless interval.title == @interval.title
              interval.pages.each do |page|
                doc.image page.image, fit: [512, 692] # minus 100 for the margin
              end
            end
          end
        end
        doc
      end

      private
        def initialize(publication, interval = EPub::Interval.null_object)
          @publication = publication
          @interval = interval
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
