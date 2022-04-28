# frozen_string_literal: true

module SolrDocumentExtensions
  module Monograph
    extend ActiveSupport::Concern

    def award
      vector('award_tesim')
    end

    def buy_url
      vector('buy_url_ssim')
    end

    def copyright_year
      scalar('copyright_year_tesim')
    end

    def creator_display
      scalar('creator_display_tesim')
    end

    def creator_full_name
      scalar('creator_full_name_tesim')
    end

    def edition_name
      scalar('edition_name_tesim')
    end

    def funder
      scalar('funder_tesim')
    end

    def funder_display
      scalar('funder_display_tesim')
    end

    def isbn
      vector('isbn_tesim')
    end

    def location
      scalar('location_tesim')
    end

    def next_edition
      scalar('next_edition_ssim')
    end

    def oclc_owi
      scalar('oclc_owi_tesim')
    end

    def open_access
      scalar('open_access_tesim')
    end

    def press
      scalar('press_tesim')
    end

    def previous_edition
      scalar('previous_edition_ssim')
    end

    def section_titles
      value = scalar('section_titles_ssim')
      value.present? ? value.split(/\r?\n/).reject(&:blank?) : value
    end

    def series
      vector('series_tesim')
    end

    def volume
      scalar('volume_tesim')
    end
  end
end
