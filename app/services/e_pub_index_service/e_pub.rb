# frozen_string_literal: true

require 'nokogiri'

module EPubIndexService
  class EPub
    attr_accessor :epub_path, :container, :content_file, :content_dir, :content
    def initialize(epub_path)
      @epub_path = epub_path
      @container = Nokogiri::XML(File.open("#{@epub_path}/META-INF/container.xml"))
      @container.remove_namespaces!

      @content_file = container.xpath("//rootfile/@full-path").text
      @content_dir = File.dirname(content_file)

      @content = Nokogiri::XML(File.open("#{@epub_path}/#{@content_file}"))
      @content.remove_namespaces!
    end
  end
end
