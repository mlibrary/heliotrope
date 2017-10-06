# frozen_string_literal: true

module EPub
  class Publication
    private_class_method :new
    attr_reader :id, :content_file, :content, :toc

    # Class Methods

    def self.clear_cache; end

    def self.from(epub, options = {})
      return null_object if epub.blank?
      noid = if epub.is_a?(Hash)
               epub[:id]
             else
               epub
             end
      return null_object unless Valid.noid?(noid)

      EPubsService.open(noid) # cache publication if it isn't already

      valid_epub = Validator.from(noid)
      return null_object if valid_epub.is_a?(ValidatorNullObject)

      new(valid_epub)
    rescue StandardError => e
      ::EPub.logger.info("Publication.from(#{epub}, #{options}) raised #{e}")
      null_object
    end

    def self.null_object
      PublicationNullObject.send(:new)
    end

    # Instance Methods

    def chapter_title_from_toc(chapter_href)
      # Navigation can be way more complicated than this, so this is a WIP
      toc.xpath("//nav/ol/li/a[@href='#{chapter_href}']").text || ""
    end

    def chapters
      chapters = []
      i = 0
      content.xpath("//spine/itemref/@idref").each do |idref|
        i += 1
        content.xpath("//manifest/item").each do |item|
          next unless item.attributes['id'].text == idref.text

          doc = Nokogiri::XML(File.open(File.join(EPubsService.epub_path(id), File.dirname(content_file), item.attributes['href'].text)))
          doc.remove_namespaces!

          chapters.push(Chapter.send(:new,
                                     item.attributes['id'].text,
                                     item.attributes['href'].text,
                                     chapter_title_from_toc(item.attributes['href'].text),
                                     "/6/#{i * 2}[#{item.attributes['id'].text}]!",
                                     doc))
        end
      end
      chapters
    end

    def presenter
      PublicationPresenter.send(:new, self)
    end

    def purge; end

    def read(file_entry = "META-INF/container.xml")
      return Publication.null_object.read(file_entry) unless Cache.cached?(id)
      EPubsService.read(id, file_entry)
    rescue StandardError => e
      ::EPub.logger.info("Publication.read(#{file_entry})  in publication #{id} raised #{e}")
      Publication.null_object.read(file_entry)
    end

    def search(query)
      return Publication.null_object.search(query) unless Cache.cached?(id)
      EPubsSearchService.new(id).search(query)
    rescue StandardError => e
      ::EPub.logger.info("Publication.search(#{query}) in publication #{id} raised #{e}") # at: #{e.backtrace.join("\n")}")
      Publication.null_object.search(query)
    end

    private

      def initialize(valid_epub)
        @id = valid_epub.id
        @content_file = valid_epub.content_file
        @content = valid_epub.content
        @toc = valid_epub.toc
      end
  end
end
