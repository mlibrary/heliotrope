# frozen_string_literal: true

module HeliotropeUniversalMetadata
  extend ActiveSupport::Concern

  included do
    property :copyright_holder, predicate: ::RDF::Vocab::SCHEMA.copyrightHolder, multiple: false do |index|
      index.as :stored_searchable
    end

    # this tracks when/if PublishJob was run for this object, it acts as a very basic piece of "audit trail" metadata *only*,...
    # and not as any kind of citation publication date value
    property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
      index.as :stored_searchable
    end

    property :doi, predicate: ::RDF::Vocab::Identifiers.doi, multiple: false do |index|
      index.as :symbol
    end
    validates :doi, format: { without: /\Ahttp.*\z/,
                              message: "Don't use full doi link. Enter e.g. 10.3998/mpub.1234567.blah" }

    property :hdl, predicate: ::RDF::Vocab::Identifiers.hdl, multiple: false do |index|
      index.as :symbol
    end

    property :holding_contact, predicate: ::RDF::URI.new('http://fulcrum.org/ns#holdingContact'), multiple: false do |index|
      index.as :symbol
    end

    property :tombstone, predicate: ::RDF::URI.new('http://fulcrum.org/ns#tombstone'), multiple: false do |index|
      index.as :symbol
    end

    property :tombstone_message, predicate: ::RDF::URI.new('http://fulcrum.org/ns#tombstone_message'), multiple: false do |index|
      index.as :stored_searchable
    end
  end
end
