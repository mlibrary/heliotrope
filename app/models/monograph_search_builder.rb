# frozen_string_literal: true
class MonographSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [:filter_by_members]

  def filter_by_members(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=id}#{asset_ids(blacklight_params['id'])}"
  end

  private

    # Get the asset/fileset ids of the monograph and the asset ids of the monograph's sections
    def asset_ids(id)
      assets = []

      ids = ActiveFedora::SolrService.query("{!terms f=id}#{id}").first['ordered_member_ids_ssim']

      if ids.present?
        docs = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}")

        section_docs = docs.select { |doc| doc['has_model_ssim'] == ['Section'].freeze }
        asset_docs   = docs.select { |doc| doc['has_model_ssim'] == ['FileSet'].freeze }

        assets << asset_docs.map(&:id)
        assets << section_docs.map { |doc| doc['ordered_member_ids_ssim'] }
      end

      assets.join(',')
    end

    def work_types
      [FileSet]
    end
end
