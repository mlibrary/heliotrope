# frozen_string_literal: true

module HeliotropeCitableLinks
  extend ActiveSupport::Concern

  included do
    property :hdl, predicate: ::RDF::Vocab::Identifiers.hdl, multiple: false do |index|
      index.as :symbol
    end

    property :doi, predicate: ::RDF::Vocab::Identifiers.doi, multiple: false do |index|
      index.as :symbol
    end
  end
end
