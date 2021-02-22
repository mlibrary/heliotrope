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
      monograph = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
      return if monograph.blank?

      docs = monograph.ordered_member_docs
      return if docs.blank?

      ids = []
      docs.each do |doc|
        next if doc['id'].in?(monograph.featured_representatives.map(&:file_set_id))
        next if doc['id'] == monograph.representative_id
        next if tombstone?(doc)
        ids << doc['id']
      end

      ids.join(",")
    end

    def tombstone?(doc)
      # HELIO-3707 ideally we'd do:
      # return true if Sighrax.tombstone?(Sighrax.from_solr_document(doc))
      # but that is N+1 and the contructors are a little complicated to change
      # The logic is simple, so:
      return true if Date.parse(doc['permissions_expiration_date_ssim'].first) <= Time.now.utc.to_date
      false
    rescue
      false
    end

    def work_types
      [FileSet]
    end
end
