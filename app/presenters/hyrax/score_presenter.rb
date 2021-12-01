# frozen_string_literal: true

module Hyrax
  class ScorePresenter < Hyrax::WorkShowPresenter
    include CommonWorkPresenter
    include CitableLinkPresenter
    include OpenUrlPresenter
    include TitlePresenter
    include SocialShareWidgetPresenter
    include FeaturedRepresentatives::MonographPresenter

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

    def catalog_url
      Rails.application.routes.url_helpers.score_catalog_path(id)
    end

    def authors(include_contributors = true)
      authorship_names = include_contributors ? [unreverse_names(solr_document.creator), unreverse_names(contributor)] : [unreverse_names(solr_document.creator)]
      authorship_names.flatten.to_sentence(last_word_connector: ' and ')
    end

    def authors?
      authors.present?
    end

    def open_access?
      true
    end

    def unreverse_names(comma_separated_names)
      forward_names = []
      comma_separated_names.each { |n| forward_names << unreverse_name(n) }
      forward_names
    end

    def unreverse_name(comma_separated_name)
      comma_separated_name.split(',').map(&:strip).reverse.join(' ')
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
