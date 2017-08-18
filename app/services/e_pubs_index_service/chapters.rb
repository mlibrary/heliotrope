# frozen_string_literal: true

require 'nokogiri'

module EPubsIndexService
  class Chapters
    def self.create(epub)
      title = epub.content.xpath("//title").text
      chapters = []

      i = 0
      epub.content.xpath("//spine/itemref/@idref").each do |idref|
        i += 1
        epub.content.xpath("//manifest/item").each do |item|
          next unless item.attributes['id'].text == idref.text

          doc = Nokogiri::XML(File.open("#{epub.epub_path}/#{epub.content_dir}/#{item.attributes['href'].text}"))
          text = doc.search('//text()').map(&:text).delete_if { |x| x !~ /\w/ }

          chapters.push(Chapter.new(title,
                                    item.attributes['id'].text,
                                    item.attributes['href'].text,
                                    "/6/#{i * 2}[#{item.attributes['id'].text}]!",
                                    text.join(" ")))
        end
      end

      chapters
    end
  end
end
