# frozen_string_literal: true

# This is almost identical to the MonographSearchBuilder.
# Maybe they should be consolidated
class ScoreSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [:filter_by_members]

  def filter_by_members(solr_parameters)
    ids = if blacklight_params[:score_id]
            # used for the facets "more" link and facet modal
            asset_ids(blacklight_params[:score_id])
          else
            asset_ids(blacklight_params['id'])
          end
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=id}#{ids}"
  end

  private

    # Get the asset/fileset ids of the monograph
    def asset_ids(id)
      score = ActiveFedora::SolrService.query("{!terms f=id}#{id}", rows: 1)
      return if score.blank?

      ids = score.first['ordered_member_ids_ssim']
      return if ids.blank?

      ids.delete(score.first['representative_id_ssim']&.first)
      featured_representatives(score.first['id']).each do |fr|
        ids.delete(fr.file_set_id)
      end

      ids.join(',')
    end

    def featured_representatives(id)
      FeaturedRepresentative.where(monograph_id: id)
    end

    def work_types
      [FileSet]
    end
end
