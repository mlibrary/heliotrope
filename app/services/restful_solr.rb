# frozen_string_literal: true

module RestfulSolr
  class << self
    def url
      ActiveFedora.solr_config[:url]
    end
  end
end
