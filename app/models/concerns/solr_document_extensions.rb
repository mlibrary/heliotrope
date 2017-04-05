module SolrDocumentExtensions
  extend ActiveSupport::Concern

  include SolrDocumentExtensions::Monograph
  include SolrDocumentExtensions::FileSet
end
