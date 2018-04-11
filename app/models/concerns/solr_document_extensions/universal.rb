# frozen_string_literal: true

module SolrDocumentExtensions::Universal
  extend ActiveSupport::Concern

  def hdl
    Array(self[Solrizer.solr_name('hdl', :symbol)]).first
  end

  def doi
    Array(self[Solrizer.solr_name('doi', :symbol)]).first
  end
end
