# frozen_string_literal: true

module EPub
  class Publication
    private_class_method :new
    attr_reader :id, :content_file, :content, :toc

    # Class Methods

    def self.clear_cache
      Cache.clear
    end

    def self.from(epub, options = {}) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return null_object if epub.blank?
      noid = epub.is_a?(Hash) ? epub[:id] : epub
      return null_object unless Valid.noid?(noid)

      file = epub[:file] if epub.is_a?(Hash)
      Cache.cache(noid, file) if file.present?
      return null_object unless Cache.cached?(noid)

      valid_epub = Validator.from(noid)
      return null_object if valid_epub.is_a?(ValidatorNullObject)

      publication = new(valid_epub)

      if file.present?
        sql_lite = EPub::SqlLite.from(publication)
        sql_lite.create_table
        sql_lite.load_chapters

        # Edge case for epubs with POI (Point of Interest) to map to CFI for a webgl (gabii)
        # See 1630
        EPub::BridgeToWebgl.cache(publication) if epub[:webgl]
      end

      publication
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
      title = toc.xpath("//nav[@type='toc']/ol/li/a[@href='#{chapter_href}']").text || ""
      # Many more ifs will come to infest this space...
      if title.blank?
        chapter_href = File.basename(chapter_href)
        title = toc.xpath("//nav[@type='toc']/ol/li/a[@href='#{chapter_href}']").text || ""
      end

      ::EPub.logger.error("Can't find chapter title for #{chapter_href}") if title.blank?
      title
    end

    def chapters
      chapters = []
      i = 0
      content.xpath("//spine/itemref/@idref").each do |idref|
        i += 1
        content.xpath("//manifest/item").each do |item|
          next unless item.attributes['id'].text == idref.text

          doc = Nokogiri::XML(File.open(File.join(::EPub.path(id), File.dirname(content_file), item.attributes['href'].text)))
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

    def purge
      Cache.purge(id)
    end

    def read(file_entry = "META-INF/container.xml")
      return Publication.null_object.read(file_entry) unless Cache.cached?(id)
      entry_file = ::EPub.path_entry(id, file_entry)
      return Publication.null_object.read(file_entry) unless File.exist?(entry_file)
      FileUtils.touch(::EPub.path(id)) # Reset the time to live for the entire cached EPUB
      File.read(entry_file)
    rescue StandardError => e
      ::EPub.logger.info("Publication.read(#{file_entry}) in publication #{id} raised #{e}") # at: #{e.backtrace.join("\n")}")
      Publication.null_object.read(file_entry)
    end

    def search(query)
      return Publication.null_object.search(query) unless Cache.cached?(id)
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
        @toc = valid_epub.toc
      end
  end
end
