# frozen_string_literal: true

module SolrDocumentExtensions
  extend ActiveSupport::Concern

  include SolrDocumentExtensions::Universal
  include SolrDocumentExtensions::Monograph
  include SolrDocumentExtensions::FileSet
end
