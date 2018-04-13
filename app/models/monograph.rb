# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  # related to our StoresCreatorNameSeparately and using Hyrax code that relies on `creator`, like CitationsBehaviors
  before_save :set_creator

  property :creator_display, predicate: ::RDF::Vocab::FOAF.maker, multiple: false do |index|
    index.as :stored_searchable
  end

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

  property :section_titles, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :symbol
  end

  include HeliotropeCitableLinks
  include StoresCreatorNameSeparately
  include ::Hyrax::WorkBehavior
  # This must come after the WorkBehavior because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  self.indexer = ::MonographIndexer

  validates :title, presence: { message: 'Your work must have a title.' }

  private

    def editor_full_name
      joining_comma = primary_editor_family_name.blank? || primary_editor_given_name.blank? ? '' : ', '
      primary_editor_family_name.to_s + joining_comma + primary_editor_given_name.to_s
    end

    def set_creator
      authors = full_name.present? ? contributor.to_a.unshift(full_name) : contributor.to_a
      editors = editor_full_name.present? ? editor.to_a.unshift(editor_full_name) : editor.to_a
      heliotrope_creators = authors + editors
      self.creator = heliotrope_creators if heliotrope_creators.present?
    end
end
