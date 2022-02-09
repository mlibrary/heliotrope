# frozen_string_literal: true

module SolrDocumentExtensions
  extend ActiveSupport::Concern

  include SolrDocumentExtensions::Universal
  include SolrDocumentExtensions::Monograph
  include SolrDocumentExtensions::FileSet

  private

    def scalar(key)
      vector(key).first
    end

    def vector(key)
      Array(self[key])
    end
end
