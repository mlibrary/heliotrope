# frozen_string_literal: true

module SolrDocumentExtensions
  module Universal
    extend ActiveSupport::Concern

    def copyright_holder
      Array(self[Solrizer.solr_name('copyright_holder', :stored_searchable)]).first
    end

    def date_published
      # note `type: :date` as this is set to a DateTime in PublishJob and, as the property is declared `stored_searchable`, it will hit this line:
      # https://github.com/samvera/active_fedora/blob/511ee837cd9a461021e53d5e20f362b634de39a8/lib/active_fedora/indexing/default_descriptors.rb#L99
      Array(self[Solrizer.solr_name('date_published', :stored_searchable, type: :date)]).first&.to_date.to_s.presence ||
          '<PublishJob never run>'
    end

    def doi
      Array(self[Solrizer.solr_name('doi', :symbol)]).first
    end

    def has_model # rubocop:disable Naming/PredicateName
      Array(self[Solrizer.solr_name('has_model', :symbol)]).first
    end

    def hdl
      Array(self[Solrizer.solr_name('hdl', :symbol)]).first
    end

    def holding_contact
      Array(self[Solrizer.solr_name('holding_contact', :symbol)]).first
    end

    def tombstone
      Array(self[Solrizer.solr_name('tombstone', :symbol)]).first
    end

    def tombstone_message
      Array(self[Solrizer.solr_name('tombstone_message', :stored_searchable)]).first
    end
  end
end
