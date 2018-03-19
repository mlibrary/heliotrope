# frozen_string_literal: true

require 'json'

module EPub
  class BridgeToWebgl
    @mapping = []

    class << self
      attr_reader :mapping
    end

    def self.cache(publication)
      json_mapfile = File.join(EPub.path(publication.id), 'epub-webgl-map.json')

      publication.chapters.each do |chapter|
        chapter.doc.xpath("//p[@data-poi]").each do |node|
          poi = node.attr('data-poi')

          indexes = []
          # This is different enough from EPub::Cfi that I'm just going to
          # cut-and-paste and endure the shame of that.
          # We're not looking for text (which EPub::Cfi assumes), we're looking
          # for elements, specifically paragraphs with a 'data-poi' attribute
          # TODO: integrate into EPub::Cfi so this is all in one place
          # this = node.parent
          this = node

          while this && this.name != "body"
            # for the hierarchy, we only care about elements
            siblings = this.parent.element_children
            idx = siblings.index(this)

            indexes << if this.text?
                         idx + 1
                       else
                         (idx + 1) * 2
                       end

            indexes[-1] = "#{indexes[-1]}[#{this['id']}]" if this['id']

            this = this.parent
          end
          indexes.reverse!

          cfi = "#{chapter.basecfi}/4/#{indexes.join('/')}"

          mapping << { poi: poi, cfi: cfi }
        end
      end

      ::EPub.logger.info("EPUB-WEBGL-MAP: #{mapping}")
      File.write(json_mapfile, mapping.to_json)
    end
  end
end
