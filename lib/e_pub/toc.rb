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
    def chapter_title(item) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      title = ""
      chapter_href = item.attributes["href"].text || ""
      if chapter_href.present?
        nav_tocs = @doc.xpath("//nav[@type='toc']")
        ::EPub.logger.info("Warning: Missing nav type toc node") if nav_tocs.empty?
        ::EPub.logger.info("Warning: Multiple nav type toc nodes!") if nav_tocs.length != 1
        nav_tocs.each do |nav_toc|
          title = nav_toc.xpath("//a[@href='#{chapter_href}']").text

          # Many more ifs will come to infest this space...
          if title.blank?
            base_href = File.basename(chapter_href)
            title = nav_toc.xpath("//a[@href='#{base_href}']").text
          end

          if title.blank?
            upone_href = "../" + chapter_href
            title = nav_toc.xpath("//a[@href='#{upone_href}']").text
          end

          break # use the first found toc only!
        end
      end
      ::EPub.logger.info("Can't find chapter title for #{chapter_href}") if title.blank?
      title
    end
  end
end
