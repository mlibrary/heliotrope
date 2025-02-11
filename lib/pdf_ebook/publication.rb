# frozen_string_literal: true

require 'open3'

module PDFEbook
  class Publication
    private_class_method :new
    attr_reader :id, :path, :outlines

    # Class Methods
    def self.from_path_id(path, id)
      new(path, id)
    rescue StandardError => e
      ::PDFEbook.logger.info("Publication.from_path_id(#{path},#{id}) raised #{e} #{e.backtrace.join("\n")}")
      PublicationNullObject.send(:new)
    end

    # Public method
    def intervals
      @intervals ||= extract_titles_and_pages(@outlines["outlines"])
    end

    private

      def extract_titles_and_pages(outlines, depth = 1)
        intervals = []
        index = 0
        outlines.each do |outline|
          intervals << PDFEbook::Interval.from_title_level_cfi(id, index, outline['title'], depth, "page=#{outline['destpageposfrom1']}")
          index += 1
          # Recursively process kids if they exist
          if outline["kids"].any?
            intervals.concat(extract_titles_and_pages(outline["kids"], depth + 1))
          end
        end

        # Add an "overall_index" to each Interval, I don't remember why we're doing this
        intervals.each_with_index { |interval, i| interval.overall_index = i }
      end

      def initialize(path, id)
        @id = id
        @path = path
        command = "qpdf --json --json-key=outlines #{@path}"
        stdin, stdout, stderr, wait_thr = Open3.popen3(command)
        stdin.close
        stdout.binmode
        out = stdout.read
        stdout.close
        err = stderr.read
        stderr.close

        raise StandardError.new "ERROR command: \"#{command}\"\n#{err}" unless wait_thr.value.success?

        @outlines = JSON.parse(out)
      end
  end

  class PublicationNullObject < Publication
    private_class_method :new

    def intervals
      []
    end

    private

      def initialize
        @path = ''
        @id = ''
      end
  end
end
