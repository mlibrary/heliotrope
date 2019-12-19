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

    # Get the asset/fileset ids of the score
    def asset_ids(id)
      score = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::ScorePresenter, presenter_args: nil).first
      return if score.blank?

      docs = score.ordered_member_docs
      return if docs.blank?

      ids = []
      docs.each do |doc|
        fp = Hyrax::FileSetPresenter.new(doc, nil)
        next if fp.featured_representative?
        next if fp.id == score.representative_id
        next if Sighrax.tombstone?(Sighrax.presenter_factory(fp))
        ids << fp.id
      end

      ids.join(",")
    end

    def work_types
      [FileSet]
    end
end
