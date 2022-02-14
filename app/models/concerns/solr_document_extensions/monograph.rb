# frozen_string_literal: true

module SolrDocumentExtensions
  module Monograph
    extend ActiveSupport::Concern

    def award
      vector(Solrizer.solr_name('award', :stored_searchable))
    end

    def buy_url
      vector(Solrizer.solr_name('buy_url', :symbol))
    end

    def copyright_year
      scalar(Solrizer.solr_name('copyright_year', :stored_searchable))
    end

    def creator_display
      scalar(Solrizer.solr_name('creator_display', :stored_searchable))
    end

    def creator_full_name
      scalar(Solrizer.solr_name('creator_full_name', :stored_searchable))
    end

    def edition_name
      scalar(Solrizer.solr_name('edition_name', :stored_searchable))
    end

    def funder
      scalar(Solrizer.solr_name('funder', :stored_searchable))
    end

    def funder_display
      scalar(Solrizer.solr_name('funder_display', :stored_searchable))
    end

    def isbn
      vector(Solrizer.solr_name('isbn', :stored_searchable))
    end

    def location
      scalar(Solrizer.solr_name('location', :stored_searchable))
    end

    def next_edition
      scalar(Solrizer.solr_name('next_edition', :symbol))
    end

    def oclc_owi
      scalar(Solrizer.solr_name('oclc_owi', :stored_searchable))
    end

    def open_access
      scalar(Solrizer.solr_name('open_access', :stored_searchable))
    end

    def press
      scalar(Solrizer.solr_name('press', :stored_searchable))
    end

    def previous_edition
      scalar(Solrizer.solr_name('previous_edition', :symbol))
    end

    def section_titles
      value = scalar(Solrizer.solr_name('section_titles', :symbol))
      value.present? ? value.split(/\r?\n/).reject(&:blank?) : value
    end

    def series
      vector(Solrizer.solr_name('series', :stored_searchable))
    end

    def volume
      scalar(Solrizer.solr_name('volume', :stored_searchable))
    end
  end
end
