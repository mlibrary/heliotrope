# frozen_string_literal: true

module EPub
  class BridgeToWebgl
    @mapping = []

    class << self
      attr_reader :mapping
    end

    def self.construct_bridge(publication)
      json_mapfile = File.join(publication.root_path, 'epub-webgl-map.json')

      publication.chapters.each do |chapter|
        chapter.doc.xpath("//p[@data-poi]").each do |node|
          poi = node.attr('data-poi')
          cfi = EPub::CFI.from(node).cfi
          mapping << { poi: poi, cfi: chapter.basecfi + cfi }
        end
      end

      ::EPub.logger.info("EPUB-WEBGL-MAP: #{mapping}")
      File.write(json_mapfile, mapping.to_json)
    end
  end
end
