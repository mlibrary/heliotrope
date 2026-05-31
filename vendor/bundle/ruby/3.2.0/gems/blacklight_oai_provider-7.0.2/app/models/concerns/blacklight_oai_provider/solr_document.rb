module BlacklightOaiProvider
  module SolrDocument
    extend ActiveSupport::Concern

    def timestamp
      timestamp = fetch(self.class.timestamp_key, nil)
      raise BlacklightOaiProvider::Exceptions::MissingTimestamp if timestamp.blank?
      Time.zone.parse(timestamp) # Solr timestamps are all in UTC.
    end

    def to_oai_dc
      export_as('oai_dc_xml')
    end

    def sets
      BlacklightOaiProvider::SolrSet.sets_for(self)
    end

    module ClassMethods
      attr_writer :timestamp_key

      def timestamp_key
        @timestamp_key ||= 'timestamp'
      end
    end
  end
end
