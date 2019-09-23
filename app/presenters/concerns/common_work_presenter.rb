# frozen_string_literal: true

module CommonWorkPresenter
  extend ActiveSupport::Concern

  def assets?
    ordered_file_sets_ids.present?
  end

  def ordered_file_sets_ids # rubocop:disable Metrics/CyclomaticComplexity
    return @ordered_file_sets_ids if @ordered_file_sets_ids
    file_sets_ids = []
    ordered_member_docs.each do |doc|
      next if doc['has_model_ssim'] != ['FileSet'].freeze
      next if doc.id == representative_id
      next if featured_representatives.map(&:file_set_id).include?(doc.id)
      next if doc['visibility_ssi'] != 'open' && !current_ability&.can?(:read, doc.id)

      file_sets_ids.append doc.id
    end
    @ordered_file_sets_ids = file_sets_ids
  end

  def ordered_member_docs
    return @ordered_member_docs if @ordered_member_docs

    ids = Array(solr_document[Solrizer.solr_name('ordered_member_ids', :symbol)])

    if ids.blank?
      @ordered_member_docs = []
      return @ordered_member_docs
    else
      query_results = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}", rows: ids.count)

      docs_hash = query_results.each_with_object({}) do |res, h|
        h[res['id']] = ::SolrDocument.new(res)
      end

      @ordered_member_docs = ids.map { |id| docs_hash[id] }
    end
  end

  def work_thumbnail(width = 225)
    img_tag = "<img class=\"img-responsive\" src="
    img_tag += if representative_id.present?
                 "\"/image-service/#{representative_id}/full/#{width},/0/default.jpg#{representative_presenter&.image_cache_breaker}\""
               else
                 "\"#{thumbnail_path}\" style=\"max-width:#{width}px\""
               end
    img_tag += " alt=\"Cover image for #{representative_alt_text}\">"
    img_tag
  end

  # This overrides CC 1.6.2's work_show_presenter.rb which is recursive.
  # Because our FileSets also have respresentative_presenters (I guess that's not normal?)
  # this recursive call from Work -> Arbitrary Nesting of Works -> FileSet never ends.
  # Our PCDM model currently only has Work -> FileSet so this this non-recursive approach should be fine
  def representative_presenter
    return nil if representative_id.blank?
    @representative_presenter ||= Hyrax::PresenterFactory.build_for(ids: [representative_id], presenter_class: Hyrax::FileSetPresenter, presenter_args: current_ability).first
  end

  # Alt text for cover page/thumbnail. Defaults to first title if not found.
  def representative_alt_text
    rep = representative_presenter
    rep.nil? || rep.alt_text.empty? ? solr_document.title.first : rep.alt_text.first
  end
end
