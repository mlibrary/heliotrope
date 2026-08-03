# frozen_string_literal: true

module EPub
  class Publication
    private_class_method :new
    attr_reader :id, :content_file, :content, :root_path

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
        # Some content has stray whitespace on a manifest item's @id (or the
        # spine itemref's @idref). EPUBCheck normalizes these before validating,
        # so such books pass validation, but an exact xpath match would miss the
        # item. Normalize both sides here so the chapter still resolves (and gets
        # indexed) the way EPUBCheck sees it. See HELIO-4314.
        idref_value = idref.text.strip
        item = content.xpath("//manifest//item[normalize-space(@id)='#{idref_value}']").first
        if item.nil?
          ::EPub.logger.warn("EPub::Publication#chapters_from_file: no manifest item matches spine idref '#{idref.text}' in #{id}")
          next
        end

        id_value = item.attributes['id'].text.strip
        href_value = item.attributes['href'].text
        doc = Nokogiri::XML(File.open(File.join(root_path, File.dirname(content_file), href_value)))
        doc.remove_namespaces!

        chapters.push(Chapter.send(:new,
                                   id: id_value,
                                   href: href_value,
                                   basecfi: "/6/#{i * 2}[#{id_value}]!",
                                   doc: doc,
                                   publication: self))
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

    def file(file_entry = "META-INF/container.xml")
      entry_file = File.join(root_path, file_entry)
      return Publication.null_object.read(file_entry) unless File.exist?(entry_file)
      entry_file
    rescue StandardError => e
      ::EPub.logger.info("Publication.file(#{file_entry}) in publication #{id} raised #{e}") # at: #{e.backtrace.join("\n")}")
      Publication.null_object.file(file_entry)
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
        @root_path = valid_epub.root_path
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

    def file(_file_entry)
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
