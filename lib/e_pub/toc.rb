# frozen_string_literal: true

module EPub
  class Toc
    attr_reader :doc
    def initialize(doc)
      @doc = doc
    end

    # The Table of Contents/Navigation of an epub can get pretty complicated
    # I'm not sure if it's just arbitrary html or if there are rules
    # As we build a "fulcrum" EPUB3 spec I imagine we'll work this out but
    # for now take what we get and try to parse it

    # @param item [Nokogiri::XML::Node] a line from the epub's //manifest/item that
    #   has an id attribute that corresponds to an idref in //spine/itemref
    # @return title [String] the chapters title
    def chapter_title(item)
      chapter_href = item.attributes["href"].text || ""

      title = @doc.xpath("//nav[@type='toc']/ol/li/a[@href='#{chapter_href}']").text

      # Many more ifs will come to infest this space...
      if title.blank?
        base_href = File.basename(chapter_href)
        title = @doc.xpath("//nav[@type='toc']/ol/li/a[@href='#{base_href}']").text
      end

      if title.blank?
        upone_href = "../" + chapter_href
        title = @doc.xpath("//nav[@type='toc']/ol/li/a[@href='#{upone_href}']").text
      end

      ::EPub.logger.error("Can't find chapter title for #{chapter_href}") if title.blank?
      title
    end
  end
end
