# frozen_string_literal: true

class MonographSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [
    :filter_by_monograph_id,
    :filter_out_miscellaneous,
    :filter_out_representatives,
    :filter_out_tombstones
  ]

  def filter_by_monograph_id(solr_parameters)
    id = monograph_id(blacklight_params)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=monograph_id_ssim}#{id}"
  end

  def filter_out_miscellaneous(solr_parameters)
    id = monograph_id(blacklight_params)
    mp = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
    return if mp.blank?

    solr_parameters[:fq] << "-id:#{mp.representative_id}" if mp.representative_id.present?

    # TODO: This isn't ideal but works. Ideally the solr document tombstone field
    # would be set to 'yes' for file sets that have past their permissions expiration date and
    # would be filtered out by the filter_out_tombstones filter method below.
    mp.ordered_member_docs.each do |doc|
      solr_parameters[:fq] << "-id:#{doc['id']}" if tombstone?(doc)
    end
  end

  def filter_out_representatives(solr_parameters)
    id = monograph_id(blacklight_params)
    # HELIO-4214 include webgls and database in the file_set/resource list
    ids = FeaturedRepresentative.where(work_id: id).filter_map { |f| f.file_set_id unless f.kind == "database" || f.kind == "webgl" }
    solr_parameters[:fq] << "-id:(#{ids.join(' ')})" if ids.present?
  end

  # Redundant but consistent with PressSearchBuilder
  def filter_out_tombstones(solr_parameters)
    # id = monograph_id(blacklight_params)
    solr_parameters[:fq] << "-tombstone_ssim:[* TO *]"
  end

  private

    def monograph_id(blacklight_params)
      blacklight_params[:monograph_id] || blacklight_params['id']
    end

    def tombstone?(doc)
      # HELIO-3707 ideally we'd do:
      # return true if Sighrax.tombstone?(Sighrax.from_solr_document(doc))
      # but that is N+1 and the contructors are a little complicated to change
      # The logic is simple, so:
      tombstone = /^yes$/i.match?(doc.tombstone)
      return true if tombstone
      Date.parse(doc['permissions_expiration_date_ssim'].first) <= Time.now.utc.to_date
    rescue StandardError => _e
      false
    end

    def work_types
      [FileSet]
    end
end
