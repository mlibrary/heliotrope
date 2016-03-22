# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include GlobalID::Identification
  validates :title, presence: { message: 'Your work must have a title.' }

  # Move this into its own concern later?
  # RDF predicates are not mapped correctly
  property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
    index.as :stored_searchable
  end
  property :isbn, predicate: ::RDF::Vocab::SCHEMA.isbn do |index|
    index.as :stored_searchable
  end
  property :editor, predicate: ::RDF::Vocab::SCHEMA.editor do |index|
    index.as :stored_searchable
  end
  property :copyright_holder, predicate: ::RDF::Vocab::SCHEMA.copyrightHolder do |index|
    index.as :stored_searchable
  end
  property :buy_url, predicate: ::RDF::Vocab::SCHEMA.sameAs do |index|
    index.as :symbol
  end

  self.indexer = MonographIndexer
end
