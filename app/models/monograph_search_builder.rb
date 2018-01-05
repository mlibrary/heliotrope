# frozen_string_literal: true

class MonographSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [:filter_by_members]

  def filter_by_members(solr_parameters)
    ids = if blacklight_params[:monograph_id]
            # used for the facets "more" link and facet modal
            asset_ids(blacklight_params[:monograph_id])
          else
            asset_ids(blacklight_params['id'])
          end
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=id}#{ids}"
  end

  private

    # Get the asset/fileset ids of the monograph
    def asset_ids(id)
      monograph = ActiveFedora::SolrService.query("{!terms f=id}#{id}", rows: 1)
      return if monograph.blank?

      ids = monograph.first['ordered_member_ids_ssim']
      return if ids.blank?

      ids.delete(monograph.first['representative_id_ssim']&.first)
      ids.delete(monograph.first['representative_epub_id_ssim']&.first)
      ids.delete(monograph.first['representative_manifest_id_ssim']&.first)
      ids.delete(monograph.first['representative_webgl_id_ssim']&.first)
      ids.join(',')
    end

    def work_types
      [FileSet]
    end
end
