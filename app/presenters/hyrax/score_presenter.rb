# frozen_string_literal: true

module Hyrax
  class ScorePresenter < Hyrax::WorkShowPresenter
    include CommonWorkPresenter
    include AnalyticsPresenter
    include CitableLinkPresenter
    include OpenUrlPresenter
    include TitlePresenter
    include SocialShareWidgetPresenter
    include FeaturedRepresentatives::MonographPresenter

    attr_reader :pageviews

    delegate :date_uploaded, :thumbnail_path, to: :solr_document

    #
    # Mixed stuff, maybe move to CommonWorkPresenter
    #
    def date_created?
      date_created.present?
    end

    def subdomain
      Array(solr_document['press_tesim']).first
    end

    def press_obj
      Press.find_by(subdomain: subdomain)
    end

    def monograph_analytics_ids
      ordered_file_sets_ids + [id]
    end

    def pageviews_count
      @pageviews ||= pageviews_by_ids(monograph_analytics_ids) # rubocop:disable Naming/MemoizedInstanceVariableName TODO: why is this not just pageviews? Change here and in monograph_presenter?
    end

    def pageviews_over_time_graph_data
      [{ "label": "Total Pageviews", "data": flot_pageviews_over_time(monograph_analytics_ids).to_a.sort }]
    end

    def catalog_url
      Rails.application.routes.url_helpers.score_catalog_path(id)
    end

    #
    # Methods we need because they're called from a partial or the
    # FileSetPresenter but are (currently) no-ops for Scores
    #
    def monograph_coins_title?; end

    def isbn_noformat
      []
    end

    def citations_ready?
      false
    end

    def creator_full_name; end

    def authors?; end

    def ordered_section_titles; end

    def previous_file_sets_id?(_id); end

    def next_file_sets_id?(_id); end

    #
    # Only score stuff
    #
    def composer
      creator.first
    end

    #
    # I'd rather not put these in model/solr_docuemnt.rb unless we really have to
    # so they don't contaminate monographs and file_sets
    #
    def amplified_electronics
      Array(solr_document['amplified_electronics_tesim']).first
    end

    def appropriate_occasion
      Array(solr_document['appropriate_occasion_tesim']).first
    end

    def bass_bells_omitted
      Array(solr_document['bass_bells_omitted_tesim']).join(' and ')
    end

    def bass_bells_required
      Array(solr_document['bass_bells_required_tesim']).join(', ')
    end

    def octave_compass
      Array(solr_document['octave_compass_tesim']).first
    end

    def composer_contact_information
      Array(solr_document['composer_contact_information_ssim']).first
    end

    def composer_diversity
      Array(solr_document['composer_diversity_tesim']).first
    end

    def duet_or_ensemble
      Array(solr_document['duet_or_ensemble_tesim']).first
    end

    def electronics_without_adjustment
      Array(solr_document['electronics_without_adjustment_tesim']).first
    end

    def musical_presentation
      Array(solr_document['musical_presentation_tesim']).first
    end

    def number_of_movements
      Array(solr_document['number_of_movements_tesim']).first
    end

    def premiere_status
      Array(solr_document['premiere_status_tesim']).first
    end

    def recommended_for_students
      Array(solr_document['recommended_for_students_tesim']).first
    end

    def solo
      Array(solr_document['solo_tesim']).first
    end
  end
end
