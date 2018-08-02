# frozen_string_literal: true

module EPub
  class Publication
    private_class_method :new
    attr_reader :id, :content_file, :content, :toc, :root_path,
                :multi_rendition, :page_scan_content_file, :ocr_content_file

    # Class Methods

    def self.from_directory(root_path)
      return null_object unless File.exist? root_path
      valid_epub = Validator.from_directory(root_path)
      return null_object if valid_epub.is_a?(ValidatorNullObject)
      new(valid_epub)
    rescue StandardError => e
      ::EPub.logger.info("Publication.from_directory(#{root_path}) raised #{e} #{e.backtrace}")
      null_object
    end

    def self.null_object
      PublicationNullObject.send(:new)
    end

    # Instance Methods

    def sections
      return @sections unless @sections.nil?
      @sections = []
      chapters.each do |chapter|
        @sections << Section.from_chapter(self, chapter) if chapter.title.present?
      end
      @sections
    end

    def chapters
      chapters = chapters_from_database || []
      chapters = chapters_from_file if chapters.empty?
      chapters
    end

    def chapters_from_database
      results = EPub::SqlLite.from_publication(self).fetch_chapters
      chapters = []
      results.each do |result|
        chapters.push(Chapter.send(:new,
                                   id: result[:id],
                                   href: result[:href],
                                   title: result[:title],
                                   basecfi: result[:basecfi],
                                   doc: Nokogiri::XML(File.open(File.join(root_path, File.dirname(content_file), result[:href]))).remove_namespaces!,
                                   publication: self))
      end
      chapters
    end

    def chapters_from_file
      chapters = []
      i = 0
      content.xpath("//spine/itemref/@idref").each do |idref|
        i += 1
        content.xpath("//manifest/item").each do |item|
          next unless item.attributes['id'].text == idref.text

          doc = Nokogiri::XML(File.open(File.join(root_path, File.dirname(content_file), item.attributes['href'].text)))
          doc.remove_namespaces!

          chapters.push(Chapter.send(:new,
                                     id: item.attributes['id'].text,
                                     href: item.attributes['href'].text,
                                     title: toc.chapter_title(item),
                                     basecfi: "/6/#{i * 2}[#{item.attributes['id'].text}]!",
                                     doc: doc,
                                     publication: self))
        end
      end
      chapters
    end

    def read(file_entry = "META-INF/container.xml")
      entry_file = File.join(root_path, file_entry)
      return Publication.null_object.read(file_entry) unless File.exist?(entry_file)
      File.read(entry_file)
    rescue StandardError => e
      ::EPub.logger.info("Publication.read(#{file_entry}) in publication #{id} raised #{e}") # at: #{e.backtrace.join("\n")}")
      Publication.null_object.read(file_entry)
    end

    def search(query)
      Search.new(self).search(query)
    rescue StandardError => e
      ::EPub.logger.info("Publication.search(#{query}) in publication #{id} raised #{e}") # at: #{e.backtrace.join("\n")}")
      Publication.null_object.search(query)
    end

    private

      def initialize(valid_epub)
        @id = valid_epub.id
        @content_file = valid_epub.content_file
        @content = valid_epub.content
        @toc = ::EPub::Toc.new(valid_epub.toc)
        @root_path = valid_epub.root_path
        @multi_rendition = valid_epub.multi_rendition
        @page_scan_content_file = valid_epub.page_scan_content_file
        @ocr_content_file = valid_epub.ocr_content_file
      end
  end

  class PublicationNullObject < Publication
    private_class_method :new

    # Instance Methods

    def chapters
      []
    end

    def read(_file_entry)
      ''
    end

    def search(query)
      { q: query, search_results: [] }
    end

    private

      def initialize
        super(Validator.null_object)
      end
  end
end
