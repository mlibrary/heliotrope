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

  property :copyright_holder, predicate: ::RDF::Vocab::SCHEMA.copyrightHolder, multiple: false do |index|
    index.as :stored_searchable
  end

  property :holding_contact, predicate: ::RDF::URI.new('http://fulcrum.org/ns#holdingContact'), multiple: false do |index|
    index.as :symbol
  end

  # this is specifically for tracking when PublishJob (which we've never used) was run
  # if we decide to get rid of PublishJob obviously this should go too
  property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
    index.as :stored_searchable
  end

  property :editor, predicate: ::RDF::Vocab::SCHEMA.editor do |index|
    index.as :stored_searchable
  end

  property :isbn, predicate: ::RDF::Vocab::SCHEMA.isbn do |index|
    index.as :stored_searchable
  end

  property :isbn_ebook, predicate: ::RDF::URI.new('http://fulcrum.org/ns#isbnEbook') do |index|
    index.as :stored_searchable
  end

  property :isbn_paper, predicate: ::RDF::URI.new('http://fulcrum.org/ns#isbnSoftcover') do |index|
    index.as :stored_searchable
  end

  property :primary_editor_family_name, predicate: ::RDF::URI.new('http://fulcrum.org/ns#primaryEditorFamilyName'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :primary_editor_given_name, predicate: ::RDF::URI.new('http://fulcrum.org/ns#primaryEditorGivenName'), multiple: false do |index|
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

  include HeliotropeCitableLinks
  include StoresCreatorNameSeparately
  include ::Hyrax::WorkBehavior
  # This must come after the WorkBehavior because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  self.indexer = ::MonographIndexer

  validates :title, presence: { message: 'Your work must have a title.' }
end
