# frozen_string_literal: true

module EditionPresenter
  extend ActiveSupport::Concern

  def previous_edition_presenter
    return @previous_edition_presenter if @previous_edition_presenter.present?
    # don't instantiate a presenter unless the link is to a Monograph in the current app this user can read
    return nil if previous_edition.blank? || previous_edition_noid.blank? || !current_ability.can?(:read, previous_edition_noid)
    @previous_edition_hash ||= ActiveFedora::SolrService.query("+id:#{previous_edition_noid} AND +has_model_ssim:Monograph", rows: 1).first&.to_h
    return nil if @previous_edition_hash.blank?
    @previous_edition_presenter ||= Hyrax::MonographPresenter.new(::SolrDocument.new(@previous_edition_hash), current_ability)
  end

  def previous_edition_url
    return nil if /https?:\/\//i.match(previous_edition).blank?
    return nil if previous_edition_noid.present? && !current_ability.can?(:read, previous_edition_noid)
    previous_edition
  end

  def next_edition_url
    return nil if /https?:\/\//i.match(next_edition).blank?
    return nil if next_edition_noid.present? && !current_ability.can?(:read, next_edition_noid)
    next_edition
  end

  def previous_edition_noid
    return @previous_edition_noid if @previous_edition_noid.present?
    @previous_edition_doi = /https?:\/\/doi.org\/(.*)/i.match(previous_edition)&.[](1)

    @previous_edition_noid ||= if @previous_edition_doi.present?
                                 ActiveFedora::SolrService.query("+doi_ssim:#{@previous_edition_doi} AND +has_model_ssim:Monograph", rows: 1).first&.id
                               else
                                 /https?:\/\/#{Rails.application.routes.default_url_options[:host]}\/concern\/monographs\/([[:alnum:]]{9})/i.match(previous_edition)&.[](1)
                               end
  end

  def next_edition_noid
    return @next_edition_noid if @next_edition_noid.present?
    @next_edition_doi ||= /https?:\/\/doi.org\/(.*)/i.match(next_edition)&.[](1)

    @next_edition_noid ||= if @next_edition_doi.present?
                             ActiveFedora::SolrService.query("+doi_ssim:#{@next_edition_doi} AND +has_model_ssim:Monograph", rows: 1).first&.id
                           else
                             /https?:\/\/#{Rails.application.routes.default_url_options[:host]}\/concern\/monographs\/([[:alnum:]]{9})/i.match(next_edition)&.[](1)
                           end
  end

  def edition_name # rubocop:disable Rails/OutputSafety
    edition_name = solr_document.edition_name
    if edition_name&.downcase&.include? 'edition'
      ", <i>#{edition_name.strip}</i>"
    elsif edition_name.present?
      " Edition, <i>#{edition_name.strip}</i>"
    elsif previous_edition.present? || next_edition.present?
      ' Edition'
    end
  end
end
