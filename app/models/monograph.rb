# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  property :creator_display, predicate: ::RDF::Vocab::FOAF.maker, multiple: false do |index|
    index.as :stored_searchable
  end

  property :buy_url, predicate: ::RDF::Vocab::SCHEMA.sameAs do |index|
    index.as :symbol
  end

  property :isbn, predicate: ::RDF::Vocab::SCHEMA.isbn do |index|
    index.as :stored_searchable
  end

  property :press, predicate: ::RDF::Vocab::MARCRelators.pbl, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  validates :press, presence: { message: 'You must select a press.' }

  property :section_titles, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :symbol
  end

  property :location, predicate: ::RDF::Vocab::DC.Location, multiple: false do |index|
    index.as :stored_searchable
  end

  property :series, predicate: ::RDF::Vocab::DCMIType.Collection do |index|
    index.as :stored_searchable, :facetable
  end

  property :open_access, predicate: ::RDF::URI.new('http://fulcrum.org/ns#OpenAccess'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :funder, predicate: ::RDF::Vocab::SCHEMA.funder, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :funder_display, predicate: ::RDF::URI.new('http://fulcrum.org/ns#FunderDisplay'), multiple: false do |index|
    index.as :stored_searchable
  end

  include HeliotropeUniversalMetadata
  include ::Hyrax::WorkBehavior
  # This must come after the WorkBehavior because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  self.indexer = ::MonographIndexer

  after_create :after_create_jobs
  after_destroy :after_destroy_jobs

  validates :title, presence: { message: 'Your work must have a title.' }

  private

    def after_create_jobs
      HandleCreateJob.perform_later(id)
    end

    def after_destroy_jobs
      HandleDeleteJob.perform_later(id)
    end
end
