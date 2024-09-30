# frozen_string_literal: true

class MonographSearchBuilder < ::SearchBuilder
  include Skylight::Helpers

  self.default_processor_chain += [
    :filter_by_monograph_id,
    :filter_out_representatives,
    :filter_out_tombstones
  ]

  # this prevents the Solr request from filtering draft documents out, given an anonymous user using a share link,...
  # otherwise the following would be added to `fq`, removing such documents from the response completely:
  # ({!terms f=edit_access_group_ssim}public) OR ({!terms f=discover_access_group_ssim}public) OR ({!terms f=read_access_group_ssim}public)"
  self.default_processor_chain -= [:add_access_controls_to_solr_params] if :valid_share_link?

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

  def valid_share_link?
    share_link = blacklight_params[:share] || session[:share_link]
    session[:share_link] = share_link

    if share_link.present?
      begin
        decoded = JsonWebToken.decode(share_link)
        return true if decoded[:data] == @monograph_presenter&.id
      rescue JWT::ExpiredSignature
        false
      end
    else
      false
    end
  end

  private

    def monograph_id(blacklight_params)
      blacklight_params[:monograph_id] || blacklight_params['id']
    end

    def work_types
      [FileSet]
    end
end
