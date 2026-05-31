module Blacklight::Gallery::OpenseadragonSolrDocument
  def to_openseadragon(view_config = nil)
    return unless view_config&.tile_source_field &&
                  fetch(view_config.tile_source_field, nil)
    Array(fetch(view_config.tile_source_field))
  end
end
