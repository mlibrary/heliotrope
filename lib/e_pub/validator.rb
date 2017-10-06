# frozen_string_literal: true

module EPub
  class Validator
    attr_reader :id, :container, :content_file, :content, :toc

    def self.from(id)
      container    = Nokogiri::XML(File.open(EPubsService.epub_entry_path(id, "META-INF/container.xml"))).remove_namespaces!
      content_file = container.xpath("//rootfile/@full-path").text
      content      = Nokogiri::XML(File.open(File.join(EPubsService.epub_path(id), content_file))).remove_namespaces!
      # EPUB3 *must* have an item with properties="nav" in it's manifest
      toc          = Nokogiri::XML(File.open(File.join(EPubsService.epub_path(id),
                                                       File.dirname(content_file),
                                                       content.xpath("//manifest/item[@properties='nav']").first.attributes["href"].value))).remove_namespaces!

      new(id: id, container: container, content_file: content_file, content: content, toc: toc)
    rescue Errno::ENOENT, NoMethodError => e
      ::EPub.logger.info("EPub::Validator.from(#{id}) raised #{e}")
      ValidatorNullObject.new
    end

    private

      def initialize(opts)
        @id           = opts[:id]
        @container    = opts[:container]
        @content_file = opts[:content_file]
        @content      = opts[:content]
        @toc          = opts[:toc]
      end
  end

  class ValidatorNullObject
    attr_reader :id, :container, :content_file, :content, :toc

    def initialize
      @id           = "null_epub"
      @container    = Nokogiri::XML(nil)
      @content_file = "empty"
      @content      = Nokogiri::XML(nil)
      @toc          = Nokogiri::XML(nil)
    end
  end
end
