module Blacklight
  module OpenseadragonHelper
    # Somewhat arbitrary number; the only important thing is that
    # it is bigger than the number of embedded viewers on a page
    ID_COUNTER_MAX = (2**20) - 1

    # Mint a (sufficiently) unique identifier, so we can associate
    # the expand/collapse control with labels
    def self.mint_id
      @id_counter = ((@id_counter || 0) + 1) % ID_COUNTER_MAX

      # We convert the ID to hex for markup compactness
      @id_counter.to_s(16)
    end

    def osd_container_class
      "col-md-6"
    end

    def osd_html_id_prefix
      "osd-#{Blacklight::OpenseadragonHelper.mint_id}".to_param
    end
  end
end
