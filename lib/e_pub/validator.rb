# frozen_string_literal: true

module EPub
  class Validator
    attr_reader :id, :container, :content_file, :content, :toc, :root_path

    def self.from_directory(root_path)
      container = Nokogiri::XML(File.open(File.join(root_path, "META-INF/container.xml"))).remove_namespaces!
      # Get the first content file (for muliple rendition epubs)
      # http://www.idpf.org/epub/renditions/multiple/
      content_file = container.xpath("//rootfile/@full-path")[0].text
      content = Nokogiri::XML(File.open(File.join(root_path, content_file))).remove_namespaces!
      # EPUB3 *must* have an item with properties="nav" in it's manifest
      toc = Nokogiri::XML(File.open(File.join(root_path,
                                              File.dirname(content_file),
                                              content.xpath("//manifest/item[@properties='nav']").first.attributes["href"].value))).remove_namespaces!

      new(id: root_path_to_noid(root_path), container: container, content_file: content_file, content: content, toc: toc, root_path: root_path)
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
    end
  end
end
