module BlacklightOaiProvider
  class SolrSet < BlacklightOaiProvider::Set
    class << self
      def search_service
        @controller.search_service
      end

      # Return an array of all sets, or nil if sets are not supported
      def all
        return if @fields.nil?

        params = { rows: 0, facet: true, 'facet.field' => solr_fields }
        solr_fields.each { |field| params["f.#{field}.facet.limit"] = -1 } # override any potential blacklight limits

        builder = search_service.search_builder.merge(params)
        response = search_service.repository.search(builder)

        sets_from_facets(response.facet_fields) if response.facet_fields
      end

      # Return a Solr filter query given a set spec
      def from_spec(spec)
        new(spec).solr_filter
      end

      # Returns array of sets for a solr document, or empty array if none are available.
      def sets_for(record)
        Array.wrap(@fields).map do |field|
          record.fetch(field[:solr_field], []).map do |value|
            new("#{field[:label]}:#{value}")
          end
        end.flatten
      end

      def fields=(value) # The Solr fields to map to OAI sets. Must be indexed
        if value.respond_to?(:each)
          value.each do |config|
            raise ArgumentException, 'OAI sets must define a solr_field' if config[:solr_field].blank?
            config[:label] ||= config[:solr_field]
          end
        end

        super(value)
      end

      def field_config_for(label)
        Array.wrap(@fields).find { |f| f[:label] == label } || {}
      end

      private

      def solr_fields
        @fields.map { |f| f[:solr_field] }
      end

      def sets_from_facets(facet_results)
        sets = Array.wrap(@fields).map do |f|
          facet_results.fetch(f[:solr_field], [])
                       .each_slice(2)
                       .map { |t| new("#{f[:label]}:#{t.first}") }
        end.flatten

        sets.empty? ? nil : sets
      end
    end

    # OAI Set properties
    attr_accessor :solr_field

    # Build a set object with, at minimum, a set spec string
    def initialize(spec)
      super(spec)
      config = self.class.field_config_for(label)
      @solr_field = config[:solr_field]
      @description = config[:description]
      raise OAI::ArgumentException if @solr_field.blank?
    end

    def name
      spec.titleize.gsub(':', ': ')
    end

    def spec
      "#{@label}:#{@value}"
    end

    def solr_filter
      "#{@solr_field}:\"#{@value}\""
    end
  end
end
