# frozen_string_literal: true

class MonographSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [:filter_by_members]

  def filter_by_members(solr_parameters)
    monograph_id = blacklight_params[:monograph_id] || blacklight_params['id']
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=monograph_id_ssim}#{monograph_id}"

    # We skip these in the blacklight results so they're not shown in the assets
    # list on the monograph_catalog page
    # solr_parameters[:fq] << "-id:(#{feat_reps_to_skip.map(&:file_set_id).join(',')})" if feat_reps_to_skip.present?
    # solr_parameters[:fq] << "id:[* TO *] -id:(#{feat_reps_to_skip.map(&:file_set_id).join(',')})" if feat_reps_to_skip.present?
    # ^^ TODO: how to do these as a single :fq?
    featured_representatives(monograph_id).each do |rep|
      solr_parameters[:fq] << "-id: #{rep.file_set_id}"
    end

    monograph = ActiveFedora::SolrService.query("{!terms f=id}#{monograph_id}", rows: 1).first
    solr_parameters[:fq] << "-id: #{monograph['representative_id_ssim']&.first}" if monograph.present? && monograph['representative_id_ssim']&.first.present?
  end

  private

    def featured_representatives(id)
      FeaturedRepresentative.where(monograph_id: id)
    end

    def work_types
      [FileSet]
    end
end
