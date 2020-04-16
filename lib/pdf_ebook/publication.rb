# frozen_string_literal: true

module PDFEbook
  class Publication
    private_class_method :new
    attr_reader :id

    # Class Methods
    def self.from_path_id(path, id)
      file = File.new(path)
      new(file, id)
    rescue StandardError => e
      ::PDFEbook.logger.info("Publication.from_path_id(#{path},#{id}) raised #{e} #{e.backtrace.join("\n")}")
      PublicationNullObject.send(:new)
    end

    def self.from_string_id(string, id)
      file = StringIO.new(string)
      new(file, id)
    rescue StandardError => e
      ::PDFEbook.logger.info("Publication.from_string_id(#{string[0..100]}) raised #{e} #{e.backtrace.join("\n")}")
      PublicationNullObject.send(:new)
    end

    # Public method
    def intervals
      @intervals ||= extract_intervals
    end

    private

      def initialize(file, id)
        @pdf = Origami::PDF.read(file, verbosity: Origami::Parser::VERBOSE_QUIET, lazy: true)
        @id = id
        @obj_to_page = {}
      end

      def extract_intervals
        # Map of PDF page object number to a page number (pages start from 1)
        if @obj_to_page.empty?
          @pdf.pages.each_with_index do |p, i|
            @obj_to_page[p.no] = i + 1
          end
        end
        @pdf.Catalog.Outlines.present? ? iterate_outlines(@pdf.Catalog.Outlines[:First]&.solve, 1) : []
      end

      # Takes Origami::OutlineItem and 1-based depth
      def iterate_outlines(outline, depth) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        intervals = []
        index = 0
        until outline.nil?
          page = nil
          page = outline&.[](:A)&.solve&.[](:D)
          if page.is_a?(Origami::Reference) # skips external links
            begin
              target = page.solve
            rescue Origami::InvalidReferenceError
              outline = outline[:Next]&.solve
              next
            end
            page = target
          elsif page.is_a?(Origami::LiteralString)
            # At this point some ToC entries are "named destinations", essentially strings for some...
            # different type of lookup directory than a page number type destination. See HELIO-3377.
            page = @pdf.get_destination_by_name(page)
          end

          page = page&.[](0)&.solve # gets to Origami::Page
          page ||= outline[:Dest]&.solve&.[](0)&.solve
          unless page.nil?
            page_number = @obj_to_page[page.no] || 0
            intervals << PDFEbook::Interval.from_title_level_cfi(id, index, outline[:Title].to_utf8, depth, "page=#{page_number}")
            index += 1
          end
          unless outline[:First]&.solve.nil? # Child outline
            intervals += iterate_outlines(outline[:First].solve, depth + 1)
          end
          outline = outline[:Next]&.solve
        end
        intervals
      end
  end

  class PublicationNullObject < Publication
    private_class_method :new

    def intervals
      []
    end

    private

      def initialize
        @pdf = ''
        @id = ''
        @obj_to_page = {}
      end
  end
end
