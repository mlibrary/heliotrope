# frozen_string_literal: true

module Sighrax
  class Work < Model
    private_class_method :new

    def children
      return [] if children_noids.blank?

      noid_entity_map = {}
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(children_noids)
      (ActiveFedora::SolrService.query(query, rows: children_noids.count) || []).each do |solr_doc|
        noid_entity_map[solr_doc.id] = ::Sighrax.from_solr_document(solr_doc)
      end

      # Preserve order of the members
      children_noids.map { |noid| noid_entity_map[noid] }
    end

    private

      def children_noids
        vector('ordered_member_ids_ssim')
      end

      def initialize(noid, data)
        super(noid, data)
      end
  end
end
