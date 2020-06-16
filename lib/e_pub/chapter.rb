# frozen_string_literal: true

require 'prawn'

module EPub
  class Chapter
    attr_accessor :id, :href, :title, :basecfi, :doc, :publication
    private_class_method :new

    # Class Methods
    def self.from_cfi(publication, cfi)
      result = EPub::SqlLite.from_publication(publication).find_by_cfi(cfi) # rubocop:disable  Rails/DynamicFindBy
      return EPub::ChapterNullObject.send(:new) if result.blank?

      new(id: result[:id],
          href: result[:href],
          title: result[:title],
          basecfi: result[:basecfi],
          doc: result[:doc],
          publication: publication)
    end

    def self.null_object
      ChapterNullObject.send(:new)
    end

    # Instance Methods
    def title?
      @title.present?
    end

    def downloadable?
      # Currently only fixed layout epubs can have downloadable chapters.
      # For reflowable/non-page-image epubs, we'll need a different process,
      # probably something like headless-chrome.
      return true if @publication.multi_rendition == 'yes' && title?
      false
    end

    def files_in_chapter
      content = Nokogiri::XML(File.open(File.join(@publication.root_path, @publication.page_scan_content_file))).remove_namespaces!
      chapter_list_file = content.xpath("//manifest/item[@id='chapterlist']").attribute("href").value
      chapter_list = Nokogiri::XML(File.open(File.join(@publication.root_path,
                                                       File.dirname(@publication.page_scan_content_file),
                                                       chapter_list_file))).remove_namespaces!
      chapter_titles = chapter_list.xpath("//ol/li/span")
      title_node = chapter_titles.map { |node| node if node.text == @title }.compact

      results = []
      title_node&.first&.parent&.traverse do |node|
        if node.attr("href").present?
          results << File.join(@publication.root_path, File.dirname(@publication.page_scan_content_file), node.attr("href"))
        end
      end
      results
    end

    def images_in_files(files)
      results = []
      files.each do |file|
        doc = Nokogiri::XML(File.open(file)).remove_namespaces!
        image = doc.xpath("//img").first.attr("src")
        image.gsub!(/^\.\.\//, '')
        results << File.join(@publication.root_path, File.dirname(@publication.page_scan_content_file), image)
      end
      results
    end

    def pdf
      return Chapter.null_object.pdf unless downloadable?
      files = files_in_chapter
      images = images_in_files(files)
      EPub.logger.info("CONVERTING #{images.count} PAGE IMAGES to PDF")
      # In Prawn, "LETTER" is 8.5x11 which is 612x792
      pdf = Prawn::Document.new(page_size: "LETTER", page_layout: :portrait, margin: 50)
      images.each do |img|
        pdf.image img, fit: [512, 692] # minus 100 for the margin
      end
      pdf
    end

    private

      def initialize(opts)
        @id = opts[:id]
        @href = opts[:href]
        @title = opts[:title]
        @basecfi = opts[:basecfi]
        @doc = opts[:doc]
        @publication = opts[:publication]
      end
  end

  class ChapterNullObject < Chapter
    private_class_method :new

    def title
      ''
    end

    def downloadable?
      false
    end

    def files_in_chapter
      []
    end

    def images_in_files(_files)
      []
    end

    def pdf
      Prawn::Document.new(page_size: "A4", page_layout: :portrait)
    end

    def downloadable_pages
      ::EPub.logger.error("Reflowable epubs never have downloadable chapters. Method downloadable_pages called from lib/e_pub/chapter.rb. Is this dead code?")
      []
    end

    private

      def initialize; end
  end
end
