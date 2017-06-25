# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Monograph`
class Monograph < ActiveFedora::Base
  property :buy_url, predicate: ::RDF::Vocab::SCHEMA.sameAs do |index|
    index.as :symbol
  end

  property :copyright_holder, predicate: ::RDF::Vocab::SCHEMA.copyrightHolder do |index|
    index.as :stored_searchable
  end

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

  property :sub_brand, predicate: ::RDF::Vocab::MARCRelators.bsl do |index|
    index.as :symbol
  end

  property :section_titles, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :symbol
  end

  include StoresCreatorNameSeparately
  include ::Hyrax::WorkBehavior
  # This must come after the WorkBehavior because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
  include StoresCreatorNameSeparatelyToSolr
  self.indexer = MonographIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }
  self.human_readable_type = 'Monograph'
end
