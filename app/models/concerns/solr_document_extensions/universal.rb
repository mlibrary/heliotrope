# frozen_string_literal: true

module SolrDocumentExtensions
  module Universal
    extend ActiveSupport::Concern

    def copyright_holder
      Array(self[Solrizer.solr_name('copyright_holder', :stored_searchable)]).first
    end

    def date_published
      Array(self[Solrizer.solr_name('date_published', :stored_searchable)])
    end

    def doi
      Array(self[Solrizer.solr_name('doi', :symbol)]).first
    end

    def hdl
      Array(self[Solrizer.solr_name('hdl', :symbol)]).first
    end

    def holding_contact
      Array(self[Solrizer.solr_name('holding_contact', :symbol)]).first
    end

    def has_model # rubocop:disable Naming/PredicateName
      Array(self[Solrizer.solr_name('has_model', :symbol)]).first
    end
  end
end
