# frozen_string_literal: true

module HeliotropeUniversalMetadata
  extend ActiveSupport::Concern

  included do
    validates :doi, format: { without: /\Ahttp.*\z/,
                              message: "Don't use full doi link. Enter e.g. 10.3998/mpub.1234567.blah" }

    # this is specifically for tracking when PublishJob (which we've never used) was run
    # if we decide to get rid of PublishJob obviously this should go too
    property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
      index.as :stored_searchable
    end

    property :copyright_holder, predicate: ::RDF::Vocab::SCHEMA.copyrightHolder, multiple: false do |index|
      index.as :stored_searchable
    end

    property :holding_contact, predicate: ::RDF::URI.new('http://fulcrum.org/ns#holdingContact'), multiple: false do |index|
      index.as :symbol
    end

    property :doi, predicate: ::RDF::Vocab::Identifiers.doi, multiple: false do |index|
      index.as :symbol
    end

    property :hdl, predicate: ::RDF::Vocab::Identifiers.hdl, multiple: false do |index|
      index.as :symbol
    end
  end
end
