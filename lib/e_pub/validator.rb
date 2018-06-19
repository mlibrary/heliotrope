# frozen_string_literal: true

module EPub
  class Validator
    attr_reader :id, :container, :content_file, :content, :toc,
                :root_path, :multi_rendition, :page_scan_content_file,
                :ocr_content_file

    def self.from_directory(root_path)
      container = Nokogiri::XML(File.open(File.join(root_path, "META-INF/container.xml"))).remove_namespaces!

      multi_rendition = container.xpath("//rootfile").length > 1 ? 'yes' : 'no'

      if multi_rendition == 'yes'
        ocr_content_file = container.xpath("//rootfiles/rootfile[@label='Text']").xpath("@full-path").text
        page_scan_content_file = container.xpath("//rootfiles/rootfile[@label='Page Scan']").xpath("@full-path").text
        content_file = ocr_content_file
      else
        content_file = container.xpath("//rootfile/@full-path").text
      end

      content = Nokogiri::XML(File.open(File.join(root_path, content_file))).remove_namespaces!
      # EPUB3 *must* have an item with properties="nav" in it's manifest
      toc = Nokogiri::XML(File.open(File.join(root_path,
                                              File.dirname(content_file),
                                              content.xpath("//manifest/item[@properties='nav']").first.attributes["href"].value))).remove_namespaces!

      new(id: root_path_to_noid(root_path),
          container: container,
          content_file: content_file,
          content: content,
          toc: toc,
          root_path: root_path,
          multi_rendition: multi_rendition,
          page_scan_content_file: page_scan_content_file,
          ocr_content_file: ocr_content_file)
    rescue Errno::ENOENT, NoMethodError => e
      ::EPub.logger.info("EPub::Validator.from_directory(#{root_path}) raised #{e}")
      ValidatorNullObject.new
    end

    def self.root_path_to_noid(root_path)
      root_path.gsub(/-epub/, '').split('/').slice(-5, 5).join('')
    end

    private

      def initialize(opts)
        @id           = opts[:id]
        @container    = opts[:container]
        @content_file = opts[:content_file]
        @content      = opts[:content]
        @toc          = opts[:toc]
        @root_path    = opts[:root_path]
        @multi_rendition = opts[:multi_rendition]
        @page_scan_content_file = opts[:page_scan_content_file]
        @ocr_content_file = opts[:ocr_content_file]
      end
  end

  class ValidatorNullObject < Validator
    def initialize(_opts = nil)
      @id           = "null_epub"
      @container    = Nokogiri::XML(nil)
      @content_file = "empty"
      @content      = Nokogiri::XML(nil)
      @toc          = Nokogiri::XML(nil)
      @root_path    = "root_path"
      @multi_rendition = "no"
      @page_scan_content_file = ""
      @ocr_content_file = ""
    end
  end
end
