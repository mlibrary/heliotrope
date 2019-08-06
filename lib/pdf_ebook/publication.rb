# frozen_string_literal: true

module PDFEbook
  class Publication
    private_class_method :new
    attr_reader :id

    # Class Methods
    def self.from_string_id(string, id)
      file = StringIO.new(string)
      new(file, id)
    rescue StandardError => e
      ::PDFEbook.logger.info("Publication.from_string_id(#{string[0..30]}) raised #{e} #{e.backtrace}")
      nil
    end

    def self.from_path_id(path, id)
      file = File.new(path)
      new(file, id)
    rescue StandardError => e
      ::PDFEbook.logger.info("Publication.from_path_id(#{path}) raised #{e} #{e.backtrace}")
      nil
    end

    # Public method
    def intervals
      @intervals ||= extract_intervals
    end

    private

      def initialize(file, id)
        @pdf = Origami::PDF.read(file, verbosity: Origami::Parser::VERBOSE_QUIET)
        @id = id
        @obj_to_page = {}
      end

      def extract_intervals
        # Map of PDF page object number to 0-based linear page number
        if @obj_to_page.empty?
          @pdf.pages.each_with_index do |p, i|
            @obj_to_page[p.no] = i
          end
        end
        @pdf.Catalog.Outlines.present? ? iterate_outlines(@pdf.Catalog.Outlines[:First]&.solve, 1) : []
      end

      # Takes Origami::OutlineItem and 1-based depth
      def iterate_outlines(outline, depth)
        intervals = []
        until outline.nil?
          page = nil
          page = outline&.[](:A)&.solve&.[](:D)&.[](0)&.solve # Origami::Page
          page ||= outline[:Dest]&.solve&.[](0)&.solve
          unless page.nil?
            page_number = @obj_to_page[page.no] || 0
            intervals << PDFEbook::Interval.from_title_level_cfi(outline[:Title].to_utf8, depth, "page=#{page_number}")
          end
          unless outline[:First]&.solve.nil? # Child outline
            intervals += iterate_outlines(outline[:First].solve, depth + 1)
          end
          outline = outline[:Next]&.solve
        end
        intervals
      end
  end
end
