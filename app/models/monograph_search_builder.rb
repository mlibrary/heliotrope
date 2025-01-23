# frozen_string_literal: true

class MonographSearchBuilder < ::SearchBuilder
  include Skylight::Helpers

  self.default_processor_chain += [
    :filter_by_monograph_id,
    :filter_out_representatives,
    :filter_out_tombstones
  ]

  # Making this method from blacklight-access_controls aware of our share links to prevents the Solr request from...
  # filtering draft documents out when an anonymous user is using a share link.
  # Otherwise the following would be added to `fq`, removing such documents from the response completely:
  # ({!terms f=edit_access_group_ssim}public) OR ({!terms f=discover_access_group_ssim}public) OR ({!terms f=read_access_group_ssim}public)"
  # method copied from here, where it's actually named `apply_gated_discovery`, it's included in the...
  # processor chain with the alias `add_access_controls_to_solr_params`:
  # https://github.com/projectblacklight/blacklight-access_controls/blob/089cb43377086adba46e4cde272c2ccb19fef5ad/lib/blacklight/access_controls/enforcement.rb#L54
  def add_access_controls_to_solr_params(solr_parameters)
    return if valid_share_link? # <-- only heliotrope change

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters.reject(&:blank?).join(' OR ')
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}") # rubocop:disable Rails/EagerEvaluationLogMessage
  end

  instrument_method
  def filter_by_monograph_id(solr_parameters)
    id = monograph_id(blacklight_params)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!terms f=monograph_id_ssim}#{id}"
  end

  instrument_method
  def filter_out_representatives(solr_parameters)
    id = monograph_id(blacklight_params)
    # ickily get the cover/representative_id from the monograph with a solr call
    doc = ActiveFedora::SolrService.query("{!terms f=id}#{id}", fl: "hasRelatedMediaFragment_ssim", rows: 1).first
    if doc.present? && doc["hasRelatedMediaFragment_ssim"].first.present?
      solr_parameters[:fq] << "-id:#{doc["hasRelatedMediaFragment_ssim"].first}"
    end

    # HELIO-4214 include webgls and database in the file_set/resource list
    ids = FeaturedRepresentative.where(work_id: id).where.not(kind: "database").where.not(kind: "webgl").map(&:file_set_id)
    solr_parameters[:fq] << "-id:(#{ids.join(' ')})" if ids.present?
  end

  instrument_method
  def filter_out_tombstones(solr_parameters)
    # I guess for tombstones in this context it's either tombstone == "yes" (or any non-blank)
    # AND/OR
    # permissions_expiration_date_ssim is anything YYYY-MM-DD before today (including today)
    solr_parameters[:fq] << "-tombstone_ssim:[* TO *]"
    solr_parameters[:fq] << "-permissions_expiration_date_ssim:[* TO #{Time.zone.today.strftime('%Y-%m-%d')}]"
  end

  private

    # note we can't access the session variable here, the `share` URL query parameter needs to be present for our...
    # Blacklight share-link override to work
    def valid_share_link?
      share_link = blacklight_params[:share]

      if share_link.present?
        begin
          decoded = JsonWebToken.decode(share_link)
          return true if decoded[:data] == monograph_id(blacklight_params)
        rescue JWT::ExpiredSignature
          false
        end
      else
        false
      end
    end

    def monograph_id(blacklight_params)
      blacklight_params[:monograph_id] || blacklight_params['id']
    end

    def work_types
      [FileSet]
    end
end
